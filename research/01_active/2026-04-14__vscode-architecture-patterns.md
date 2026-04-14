# Visual Studio Code 実装パターン整理（転用向け）

作成日: 2026-04-14

## 0. 目的

VS Code の実装を、**他ツールへ転用できる設計資料**として整理する。
- 実装詳細を丸写しするのではなく、
- 「どの責務をどこへ置くか」「依存をどう切るか」「イベントをどう流すか」を主眼にまとめる。

---

## 1. 結論（先に要点）

VS Code は単一パターンではなく、次の組み合わせで成立している。

1. **マルチプロセス分離**（UI/メイン/Extension Host）
2. **イベント駆動**（`Emitter`/`Event` を中心）
3. **DI + サービスレジストリ**（`createDecorator` と `registerSingleton`）
4. **コントリビューション登録モデル**（起動時登録 + 遅延活性化）
5. **RPC/プロトコル境界**（Main Thread ↔ Ext Host）
6. **層・環境分割**（`base/platform/editor/workbench/code/server` と `common/browser/node/...`）

### ヘキサゴナルとの関係

- **思想としては近い**（中心を抽象インターフェースに置き、外部をアダプターで接続）。
- ただし VS Code は現実解として、
  - UI とワークベンチ寄りの都合、
  - Electron/Browser/Node という実行環境差分、
  - レジストリ型の拡張モデル
  を強く持つため、**純粋なヘキサゴナルを厳格適用した構造ではない**。

> 実務上は「**ヘキサゴナル志向のサービス指向 + イベント駆動 + プロセス境界アダプター**」と捉えるのが転用しやすい。

---

## 2. 公式リポジトリで確認できる構造

公式 Wiki「Source Code Organization」で、層と依存ルールが明示されている。

- `base`: 汎用ユーティリティ
- `platform`: DI/基盤サービス
- `editor`: Monaco Core
- `workbench`: VS Code UI フレームワーク
- `code`: デスクトップエントリ
- `server`: リモート開発向け

また、ターゲット環境を `common/browser/node/electron-*` に分け、
「使ってよい API の境界」をコード配置で担保している。

### 転用ポイント

- 最初に層を切り、**依存方向を固定**する。
- 実行環境差分（CLI/Web/Desktop）をディレクトリ分割で明示する。

---

## 3. 主なクラス/概念の分け方（VS Code流）

## 3.1 Event（出来事）

`src/vs/base/common/event.ts` にある `Emitter`/`Event` が中核。

- 状態変化を pull ではなく push で通知
- UI やサービス同士を疎結合化
- dispose と組み合わせてリーク管理

### 転用指導

- まず同期呼び出しで作るのではなく、
  - 「何をイベントとして公開するか」を先に設計する。
- ドメインイベント（例: `TaskStarted`, `TaskFailed`）を API にする。
- 各イベント購読解除（dispose）を必須運用にする。

## 3.2 Service（能力）

`src/vs/platform/instantiation/common/instantiation.ts` で `createDecorator` を使ったサービス識別子。
`extensions.ts` 側で `registerSingleton` による実装登録。

- 依存先は「クラス」ではなく「サービス識別子」にする
- 実装差し替え（Web/Desktop/Mock）が容易

### 転用指導

- 依存は `interface` + `Service ID` 単位で宣言。
- 実装クラスは composition root（起動時設定）で束ねる。
- テストでは mock 実装を差し込む。

## 3.3 Contribution（機能追加）

`workbench/contrib` 配下で、機能を登録点にぶら下げる方式。

- コアは最小化
- 機能は自己完結モジュールとして追加
- 起動時に読み込むが、実動作は遅延させる

### 転用指導

- 「機能本体」より先に「登録契約（manifest）」を決める。
- `contribution.ts` 的な **1エントリ規約** を作る。
- 監査しやすい（どこで何を登録したか追える）構造を優先。

## 3.4 Protocol / Bridge（境界越え）

Extension Host とメイン側は直接参照しない。
プロトコル（RPC）で通信する。

- 代表: `extHost.protocol.ts`, `extensionHostProcess.ts`
- 失敗時はホストのみ再起動可能（耐障害性）

### 転用指導

- 重い処理・不安定処理は別プロセス/別ワーカーへ隔離。
- 境界は「メッセージ契約」を先に固定。
- 双方向 API は `MainThreadX` / `ExtHostX` のようにペアで設計。

---

## 3.5 Adapter Pattern（VS Code対比）

Adapter は、VS Code では「外部/環境差分を吸収して内部契約へ合わせる」ために多用される。

### VS Code での見え方

- **実行環境アダプタ**
  - `browser` / `node` / `electron-*` の配置分割で、同じ上位契約に異なる下位実装を接続
- **拡張ホスト境界アダプタ**
  - Ext Host API と Main Thread API の間で、プロトコル単位の変換を行う
- **インフラ吸収アダプタ**
  - ファイル、通知、ホスト制御などを platform service 経由で抽象化し、実体を差し替える

### 他ツールへ転用する場合

- 内部は `IStorageService` だけ見せる
- 外部ごとに `S3StorageAdapter` / `LocalFsStorageAdapter` / `InMemoryStorageAdapter` を作る
- 起動時に DI で 1 つを接続する

```ts
interface IStorageService {
  read(path: string): Promise<Uint8Array>;
}

class LocalFsStorageAdapter implements IStorageService { /* ... */ }
class S3StorageAdapter implements IStorageService { /* ... */ }
```

### 有用性（Adapter）

- ドメイン側が外部 SDK 変更の影響を受けにくい
- Web/Desktop/Server 差分を実装分岐ではなく実装差し替えで扱える
- テストで in-memory adapter を使える

### 煩雑さ（Adapter）

- インターフェースと実装クラスが増える
- 変換処理（DTO/エラーコード変換）が散らばりやすい
- 「何でも抽象化」すると過剰設計になる

---

## 3.6 Command Pattern（VS Code対比）

Command は VS Code で「機能の呼び出し面を統一」する中核パターン。
`commands.ts` 系でコマンド ID とハンドラを登録し、UI（メニュー/キー操作/パレット）と処理を疎結合にする。

### VS Code での見え方

- コマンドは **ID文字列 + handler** で登録
- 呼び出し側は ID を知っていれば実行できる
- UI 要素（コマンドパレット、キーバインド、メニュー）と実処理が分離される

### 他ツールへ転用する場合

```ts
// register
commands.registerCommand('task.run', async (taskId: string) => { /* ... */ });

// invoke
await commands.executeCommand('task.run', 'build:prod');
```

### 有用性（Command）

- 呼び出し経路が統一される（UI/API/自動化が同じ入口）
- 機能追加時に UI と処理を別チームで進めやすい
- 拡張機能やプラグインに公開しやすい

### 煩雑さ（Command）

- 文字列 ID ベースはリネーム耐性が弱い（型安全を失いやすい）
- コマンド乱立で発見性が落ちる（命名規約・分類が必要）
- ハンドラの副作用が増えると追跡コストが上がる

---

## 4. 依存関係の基本形

```text
[UI / Workbench]
   | uses services (DI)
   v
[Platform Services] <---- registerSingleton ---- [Implementations]
   |
   | emits/listens events
   v
[Event Bus / Emitter]

[Extension Host] <---- RPC protocol ----> [Main Thread / Workbench]
```

### 依存ルール（転用時テンプレ）

1. 上位は下位抽象に依存（具象直参照しない）
2. `contrib` はコア内部へ逆依存しない
3. 環境固有コード（web/node/desktop）は境界外へ閉じ込める
4. 外部連携は adapter 層へ隔離

---

## 5. 「各ファイルで定義している概念・機能」サンプル

以下は、調査対象として押さえるべき代表ファイル（詳細実装ではなく概念把握向け）。

- `src/vs/base/common/event.ts`
  - `Event` 抽象、`Emitter`、イベント変換ユーティリティ
- `src/vs/platform/instantiation/common/instantiation.ts`
  - サービス識別子、DI インスタンス化契約
- `src/vs/platform/instantiation/common/extensions.ts`
  - サービス実装の登録 (`registerSingleton`)
- `src/vs/workbench/browser/workbench.ts`
  - Workbench ライフサイクルと UI 初期化の中核
- `src/vs/workbench/api/common/extHost.protocol.ts`
  - Main Thread / Ext Host 間プロトコル型定義
- `src/vs/workbench/api/node/extensionHostProcess.ts`
  - Ext Host プロセス起動・接続・終了制御
- `src/vs/platform/commands/common/commands.ts`
  - コマンドの登録・実行契約（Command Pattern の中核）

---

## 6. 他ツールへ転用する際の実装テンプレ

## 6.1 最小構成（サンプル）

```ts
// platform/ids.ts
export const ITaskService = createDecorator<ITaskService>('taskService');

// platform/registration.ts
registerSingleton(ITaskService, TaskService, InstantiationType.Delayed);

// domain/taskService.ts
export interface ITaskService {
  readonly onDidTaskStateChange: Event<TaskState>;
  run(taskId: string): Promise<void>;
}

// domain/taskServiceImpl.ts
class TaskService implements ITaskService {
  private readonly _onDidTaskStateChange = new Emitter<TaskState>();
  readonly onDidTaskStateChange = this._onDidTaskStateChange.event;

  async run(taskId: string) {
    this._onDidTaskStateChange.fire({ taskId, phase: 'started' });
    // ... do work
    this._onDidTaskStateChange.fire({ taskId, phase: 'done' });
  }
}
```

## 6.2 プロセス分離（必要時）

```text
UI process
  -> protocol.send({type: 'runTask', id})
Worker/Host process
  -> executes heavy logic
  -> protocol.send({type: 'taskProgress', ...})
```

### 採用判断

- 100ms 超の重処理が UI 体感へ影響するなら分離検討
- サードパーティ実行を許すなら分離は原則必須

---

## 7. 設計思想（指導重点）

1. **拡張を前提にコアを小さく保つ**
   - 追加機能は contribution として差し込む。
2. **不安定要素を隔離する**
   - 拡張・外部コマンド・重処理は別境界へ。
3. **同期呼び出しより契約を優先する**
   - イベント契約、サービス契約、RPC契約を先に定義。
4. **起動時の全読み込みを避ける**
   - activation/lazy load を標準化。
5. **環境差分を構造化して持つ**
   - Browser/Node/Desktop の差分を実装ではなく配置規約で吸収。
6. **外部依存は Adapter、操作入口は Command で揃える**
   - 変更に強い境界（Adapter）と拡張しやすい実行面（Command）を分離する。

---

## 8. 30件の調査リンク（リポジトリ + 公式中心）

> 注: 実装根拠は一次情報（公式リポジトリ/公式ドキュメント）を主軸に参照。

1. https://github.com/microsoft/vscode
2. https://github.com/microsoft/vscode/wiki/source-code-organization
3. https://github.com/microsoft/vscode/wiki
4. https://code.visualstudio.com/api/advanced-topics/extension-host
5. https://code.visualstudio.com/api/get-started/extension-anatomy
6. https://code.visualstudio.com/api/extension-capabilities/overview
7. https://code.visualstudio.com/api/references/vscode-api
8. https://code.visualstudio.com/api/ux-guidelines/overview
9. https://code.visualstudio.com/api/ux-guidelines/webviews
10. https://code.visualstudio.com/api/extension-guides/virtual-workspaces
11. https://code.visualstudio.com/api/extension-guides/ai/ai-extensibility-overview
12. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/base/common/event.ts
13. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/platform/instantiation/common/instantiation.ts
14. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/platform/instantiation/common/extensions.ts
15. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/browser/workbench.ts
16. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/api/common/extHost.protocol.ts
17. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/api/node/extensionHostProcess.ts
18. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/workbench.common.main.ts
19. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/workbench.desktop.main.ts
20. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/workbench.web.main.ts
21. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/code/electron-main/main.ts
22. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/code/electron-browser/workbench/workbench.ts
23. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/platform/commands/common/commands.ts
24. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/platform/files/common/files.ts
25. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/platform/configuration/common/configuration.ts
26. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/platform/notification/common/notification.ts
27. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/services/extensions/common/extensions.ts
28. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/services/lifecycle/common/lifecycle.ts
29. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/services/host/browser/browserHostService.ts
30. https://raw.githubusercontent.com/microsoft/vscode/main/src/vs/workbench/services/environment/common/environmentService.ts

---

## 9. 実装時チェックリスト（転用用）

- [ ] サービスは interface と ID で公開されているか
- [ ] 機能追加の登録点（contribution）が一本化されているか
- [ ] UI が重処理を直実行していないか
- [ ] イベントの dispose 漏れがないか
- [ ] Browser/Node/Desktop 差分が混線していないか
- [ ] 失敗時に部分再起動できる境界があるか
