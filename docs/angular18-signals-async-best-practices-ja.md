# Angular 18 Signals + 非同期処理 ベストプラクティス集（2026-04-14調査）

## 調査方針
- Angular 18 を前提に、Signals / effect / computed / HttpClient / RxJS interop の公式ドキュメント中心で整理。
- `linkedSignal` / `resource` は **Angular 18 公式ガイドには掲載がなく**、現行 `angular.dev` では確認できるため、
  Angular 18 時点では「未導入（または非対象）」として代替案を提示。
- 検索件数: 60件（検索エンジン結果を60件スクリーニング）。

---

## 結論（先に要点）
1. **画面状態は Signal、I/O 境界は Observable（HttpClient）** が Angular 18 で最も安全。
2. **effect は「副作用（ログ、localStorage、外部UI同期）」に限定**。状態伝播に使わない。
3. サイドバー一覧 + 右詳細は、
   - `selectedId` を writable signal
   - `detailsCache` / `detailLoadState` も writable signal
   - ユーザー操作ハンドラ内で `await` + `signal.set/update`
   でほぼ実装できる（effect不要）。
4. `linkedSignal` 相当は Angular 18 では
   - `writable + computed + 明示的リセット`（イベント駆動）
   - もしくは「base signal と draft signal の二層化」
   で代替。
5. 編集UIは `computed` 単体では不可（readonly）なので、
   **`serverState` と `draftState` を分離**する。

---

## 1) effect をできるだけ使わない実装（推奨）

### 1-1. 画面モデル（サイドバー一覧 + 選択詳細）
- `projects = signal<Project[]>([])`
- `selectedProjectId = signal<string | null>(null)`
- `projectDetailsById = signal<Record<string, ProjectDetail>>({})`
- `detailLoadingById = signal<Record<string, boolean>>({})`
- `detailErrorById = signal<Record<string, string | null>>({})`
- `selectedDetail = computed(() => {
   const id = selectedProjectId();
   return id ? projectDetailsById()[id] ?? null : null;
  })`

### 1-2. 非同期ロード戦略
- 初回一覧は `ngOnInit` / `constructor` から `loadList()` を明示実行。
- 詳細は `onSelectProject(id)` の中でのみロード。
- すでに `projectDetailsById()[id]` があれば再取得しない（キャッシュ）。
- 取得中フラグやエラーは id 単位で持つ。

> ポイント: 「signal変更をトリガにeffectでAPIコール」ではなく、**ユーザーイベントを起点**にする。

---

## 2) effect を使うべきケースと共通化

### 2-1. effect を使うべきケース
- 画面状態を外部へ反映するだけの処理
  - analytics送信
  - localStorage同期
  - canvas/chart など imperative API 連携

### 2-2. 共通化方法
- `createStorageSyncEffect<T>(key: string, s: Signal<T>)`
- `createAnalyticsEffect<T>(name: string, s: Signal<T>)`
- ドメインサービスに閉じ込め、コンポーネントからは生成関数を呼ぶだけ。

### 2-3. 禁止寄り
- effect内で別signalへ `.set()` して状態を伝播。
  - ループ/不整合/ExpressionChanged 系温床。

---

## 3) linkedSignal がない前提（Angular 18）での代替

### 3-1. 代替A: writable + computed + 再同期関数
- `source`: サーバーの正本（`selectedProjectFromCache`）
- `draft`: 編集用 writable signal
- `resetDraftFromSource()` を明示的に呼ぶ
  - 選択変更時
  - 保存成功時
  - 取消時

### 3-2. 代替B: key付き draft map
- `draftById = signal<Record<string, DraftProject>>({})`
- `selectedDraft = computed(() => draftById()[selectedId()] ?? createDraft(base))`
- 編集は `draftById.update(...)`

### 3-3. 代替C: バージョン管理
- `serverVersion` と `draftVersion` を分離。
- 不一致なら「サーバー更新あり」バナー表示。

---

## 4) computed が readonly 問題と編集UI最適解

### 推奨二層モデル
- **Read model**: `computed`（表示専用）
- **Write model**: `writable signal`（フォーム編集）

例:
- `projectBase = computed(() => cache[selectedId])`
- `projectDraft = signal<ProjectDraft | null>(null)`
- 選択時に `projectDraft.set(structuredClone(projectBase()))`
- 保存時に API -> 成功後 `cache.update` と `projectDraft.set(newValue)`

---

## 5) signal.set したのに再描画されない時の原因

### Angular が変更検知とみなすもの
- Signalは既定で **`Object.is`（参照等価）** 比較。
- `set` / `update` しても「等価」と判定されれば依存は無効化されない。

### よくある原因
1. オブジェクト/配列を破壊的変更して同一参照を再セット。
2. template で signal を関数呼び出し `foo()` せず `foo` を参照。
3. OnPush 配下でその signal を template で読んでいない。
4. `untracked` の使い方で依存追跡を外している。
5. カスタム `equal` が強すぎる（更新抑制しすぎ）。

### 対策
- 不変更新を徹底（新しい参照を返す）。
- 必要なら `equal` を見直す。
- 表示で実際に読んでいる signal を点検。

---

## 6) RxJSは使うべきか？（Angular 18）

### 実務推奨
- **全面禁止は非推奨**。
- ただし「状態管理の主軸」は Signals に寄せて良い。
- RxJSは以下に限定すると複雑度を抑えやすい。
  1. HttpClient（戻り値がObservable）
  2. 複数非同期ストリーム合成（`switchMap`など）
  3. キャンセル/再試行/デバウンスが重要な箇所

### 限定的利用パターン
- Service層でのみ RxJS を使い、コンポーネントでは `await firstValueFrom(...)`。
- もしくは service で `toSignal` 化しUIへ `Signal` で渡す。

---

## 7) 非同期で RxJS を極小化する実装パターン

1. `firstValueFrom(http.get(...))` + signal.set
2. `fetch` + `AbortController` + signal.set
3. PromiseベースAPIラッパを作る
4. リクエストIDで競合排除（latest-wins）
5. id別キャッシュ + stale-while-revalidate
6. 明示的 `reload()` 関数
7. `loading/error/data` 3信号セット
8. 楽観更新 + 失敗時ロールバック
9. フォーム編集は draft分離
10. 一覧は先読み、詳細は遅延読み込み

---

## 8) APIレスポンスをSignalとして扱う「うまい」型

### 推奨: ResourceState型
```ts
interface ResourceState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  fetchedAt: number | null;
}
```
- `resourceByKey = signal<Record<string, ResourceState<ProjectDetail>>>({})`
- 更新は必ず `update(prev => ({ ...prev, [key]: next }))`
- キャッシュヒット時は即表示 + 裏で再取得。

---

## 9) よくある実装パターン（最低10、effect極小）

1. **イベント駆動ロード**: 選択イベントで詳細取得。
2. **id別キャッシュ**: 詳細再訪問を高速化。
3. **latest-wins**: request tokenで古い応答を破棄。
4. **3状態管理**: `data/loading/error` を分離。
5. **二層編集モデル**: `base` + `draft`。
6. **楽観更新**: 更新前にUI反映、失敗時巻き戻し。
7. **部分更新**: detail mapの該当idのみ差し替え。
8. **検索語signal + 明示検索ボタン**（無駄API防止）。
9. **保存dirty判定computed**: `isDirty` を導出。
10. **再取得ポリシーsignal**: `ttlMs` / `lastFetchedAt`。
11. **ページ離脱時破棄**: 明示 reset。
12. **共通ローダー関数**: `loadByKey(key, fetcher)`。

### 9-1) 各パターンの最小サンプルコード

> 前提: `signal`, `computed` は `@angular/core`。

1) **イベント駆動ロード**
```ts
async function selectProject(id: string) {
  selectedId.set(id);
  if (!detailsById()[id]) {
    const detail = await fetchProjectDetail(id);
    detailsById.update(prev => ({ ...prev, [id]: detail }));
  }
}
```

2) **id別キャッシュ**
```ts
const detailsById = signal<Record<string, ProjectDetail>>({});

function getCached(id: string) {
  return detailsById()[id] ?? null;
}
```

3) **latest-wins**
```ts
const requestSeq = signal(0);

async function loadDetailLatest(id: string) {
  const seq = requestSeq() + 1;
  requestSeq.set(seq);
  const detail = await fetchProjectDetail(id);
  if (seq !== requestSeq()) return; // 古いレスポンスを破棄
  detailsById.update(prev => ({ ...prev, [id]: detail }));
}
```

4) **3状態管理**
```ts
type LoadState<T> = { data: T | null; loading: boolean; error: string | null };
const detailState = signal<LoadState<ProjectDetail>>({ data: null, loading: false, error: null });
```

5) **二層編集モデル（base + draft）**
```ts
const base = computed(() => detailsById()[selectedId() ?? ''] ?? null);
const draft = signal<ProjectDetail | null>(null);

function resetDraft() {
  draft.set(base() ? structuredClone(base()!) : null);
}
```

6) **楽観更新 + 失敗時ロールバック**
```ts
async function saveOptimistic(next: ProjectDetail) {
  const id = next.id;
  const before = detailsById()[id];
  detailsById.update(prev => ({ ...prev, [id]: next }));
  try {
    await saveProject(next);
  } catch {
    detailsById.update(prev => ({ ...prev, [id]: before }));
  }
}
```

7) **部分更新（該当idのみ差し替え）**
```ts
function patchDetail(id: string, patch: Partial<ProjectDetail>) {
  const cur = detailsById()[id];
  if (!cur) return;
  detailsById.update(prev => ({ ...prev, [id]: { ...cur, ...patch } }));
}
```

8) **検索語signal + 明示検索ボタン**
```ts
const keyword = signal('');

async function onClickSearch() {
  list.set(await fetchProjects({ keyword: keyword() }));
}
```

9) **dirty判定computed**
```ts
const isDirty = computed(() => {
  const b = base();
  const d = draft();
  return JSON.stringify(b) !== JSON.stringify(d);
});
```

10) **再取得ポリシー（ttl + lastFetchedAt）**
```ts
const ttlMs = signal(30_000);
const fetchedAtById = signal<Record<string, number>>({});

function shouldRefetch(id: string) {
  const at = fetchedAtById()[id] ?? 0;
  return Date.now() - at > ttlMs();
}
```

11) **ページ離脱時破棄（明示reset）**
```ts
function resetPageState() {
  selectedId.set(null);
  draft.set(null);
  detailState.set({ data: null, loading: false, error: null });
}
```

12) **共通ローダー関数**
```ts
async function loadByKey<T>(
  key: string,
  fetcher: () => Promise<T>,
  state: WritableSignal<Record<string, LoadState<T>>>,
) {
  state.update(prev => ({ ...prev, [key]: { data: prev[key]?.data ?? null, loading: true, error: null } }));
  try {
    const data = await fetcher();
    state.update(prev => ({ ...prev, [key]: { data, loading: false, error: null } }));
  } catch (e) {
    state.update(prev => ({ ...prev, [key]: { data: null, loading: false, error: String(e) } }));
  }
}
```

---

## 10) よくあるアンチパターン（最低10）

1. effectでAPIを連鎖実行して状態伝播。
2. effect内set乱用（循環更新）。
3. 破壊的変更（push/splice直書き）後に同参照set。
4. 1つの巨大signalへ全画面状態を詰め込む。
5. `any` 多用で state shape 崩壊。
6. loading/errorを持たず data だけ管理。
7. 詳細選択のたびに毎回フル再取得（キャッシュ無し）。
8. request競合未対策で古いレスポンスが勝つ。
9. computedを編集元にしようとして無理に回避。
10. RxJSを完全排除して逆に複雑な自作キャンセル処理。
11. toSignalを毎回作り直して多重購読。
12. untracked濫用で依存関係が見えなくなる。

---

## 11) サンプル設計（サイドバー一覧 + 詳細 + 編集）

### 状態
- `listState: Signal<ResourceState<Project[]>>`
- `selectedId: WritableSignal<string | null>`
- `detailsStateById: WritableSignal<Record<string, ResourceState<ProjectDetail>>>`
- `draftById: WritableSignal<Record<string, ProjectDraft>>`

### フロー
1. 初期表示: `loadProjectList()`
2. 一覧選択: `selectProject(id)`
   - `selectedId.set(id)`
   - 詳細未取得なら `loadDetail(id)`
   - draft未生成なら base から作成
3. 編集: `updateDraftField(id, patch)`
4. 保存: `saveProject(id)`
   - 楽観 or 悲観更新
   - 成功で `detailsStateById` と `draftById` 再同期

---

## 12) Angular 18での実装判断表

- 画面内局所状態: Signals（第一選択）
- 複雑ストリーム（キャンセル/合成/時間演算）: RxJS（限定利用）
- state導出: computed
- 外部副作用: effect（限定）
- linkedSignal相当: draft分離 + 明示同期

---

## 参考（一次情報中心）
- Angular v18 Signals Guide
- Angular v18 RxJS Interop Guide
- Angular v18 HttpClient Guide
- Angular Signals Guide（現行）
- linkedSignal Guide（現行）
- resource Guide（現行）


---

## 13) linkedSignal同等挙動の実装サンプル（Angular 18 / effectなし）

Zenn記事（https://zenn.dev/lacolaco/articles/angular-v19-linked-signal）で紹介されている、
`computed(() => signal(...))` パターンをAngular 18向けに関数化した。

- 実装ファイル: `docs/examples/linked-signal-like.sample.ts`
- 実装方針:
  - `innerWritable = computed(() => signal(computation(source())))`
  - 返却値は `WritableSignal<T>`（`linkedSignal`同様）
  - `set/update` は `innerWritable().set/update` へ委譲
  - `effect` は使わない

`FavoriteFoodSelector` 例（要件どおり）:
- `options = input(initialOptions)`
- `selectedFood = linkedSignalLike({ source: this.options, computation: () => null })`
- `selectFood(food) { this.selectedFood.set(food) }`

想定フロー（プロジェクト詳細編集）:
1. 一覧選択時に詳細取得（必要なら）
2. `projectDraft()` 参照で、最新sourceに対応する内側signalへアクセス
3. フォーム編集は `projectDraft.set(...)`
4. 保存成功後はキャッシュ更新し `projectDraft()` を参照

---

## 14) linkedSignalだけでなくresourceもAngular 18で再現できるか？

結論: **可能（限定的に）**。ただしAngular v19+ の `resource` 完全互換ではなく、
Angular 18では `signal + computed + 明示load/reload` で「resource風」を作るのが現実的。

実装例: `docs/examples/resource-like.sample.ts`

### 提供している機能
- `status`: `idle | loading | reloading | resolved | error`
- `value`, `error`, `isLoading`, `hasValue`
- `load()`, `reload()`, `abort()`
- latest-wins（古いレスポンス破棄）
- `AbortController` 連携

### 使い方（要点）
1. `params` を signal で定義（例: `selectedProjectId`）
2. `createResourceLike({ params, loader })` を生成
3. `onSelectProject(id)` で `params.set(id)` + `await load()`
4. 再試行は `reload()`

### 注意点
- v19+ `resource` の完全同等ではない（API/挙動差分あり）
- Angular 18では「明示イベント駆動」で管理するほうがデバッグしやすい

---

## 15) 追加収集した実装パターン（lacolaco + Angular18系GitHubハック）

以下は、lacolaco氏の記事群とAngular 18系の公開リポジトリ/周辺エコシステムで
実際に使われることの多い「現場ハック」を整理したもの。

### 15-1. lacolaco由来の実装パターン

1. **Signal of Signals（computed内でsignalを返す）**
   - 目的: `linkedSignal` がない環境で「source変更時リセット + 編集可能値」を実現。
   - 出典: `Angular v19: linkedSignal() の解説`。
   - URL: https://zenn.dev/lacolaco/articles/angular-v19-linked-signal

```ts
const selectedFood = computed(() => {
  options();
  return signal<string | null>(null);
});

function selectFood(food: string) {
  selectedFood().set(food);
}
```

2. **effect内の同期writeを避ける（v18設計思想）**
   - 目的: ループ/競合を避け、導出状態は `computed` に寄せる。
   - 出典: `Angular v19: effect() の変更点`（v18の挙動差分解説）。
   - URL: https://zenn.dev/lacolaco/articles/angular-v19-effect-changes

3. **コンポーネント間通信で「input/output + Signal」を混ぜる**
   - 目的: 全部Signalに寄せるより、境界で責務を明確化。
   - 出典: `Angular Signalsとコンポーネント間通信`。
   - URL: https://zenn.dev/lacolaco/articles/angular-signals-and-component-communication

### 15-2. Angular18系GitHubで多いハック

4. **fetch + signal の軽量ローダー（HttpClientを使わない最小構成）**
   - 目的: 小規模画面で RxJS 配管を最小化。
   - 参考: `nicetomytyuk/angular-18-fetch-signals-example`。
   - URL: https://github.com/nicetomytyuk/angular-18-fetch-signals-example

```ts
const loading = signal(false);
const error = signal<string | null>(null);
const data = signal<Item[]>([]);

async function load() {
  loading.set(true);
  error.set(null);
  try {
    data.set(await fetch('/api/items').then(r => r.json()));
  } catch (e) {
    error.set(String(e));
  } finally {
    loading.set(false);
  }
}
```

5. **Signal Storeを“service内signal”から段階導入**
   - 目的: 既存RxJS/NgRxから一気に置換しない。
   - 参考: `zuriscript/signalstory`, `ngrx-signal-store-playground`。
   - URL: https://github.com/zuriscript/signalstory
   - URL: https://github.com/markostanimirovic/ngrx-signal-store-playground

6. **immutable強制ハック（mutation事故防止）**
   - 目的: `set/update` しても再描画されない事故を削減。
   - 参考: `@angular-architects/ngrx-toolkit` の `withImmutableState`。
   - URL: https://github.com/angular-architects/ngrx-toolkit

7. **状態同期は explicitEffect で依存を明示**
   - 目的: effect乱用を避け、依存シグナル集合を明示化。
   - 参考: `ngxtension explicitEffect`。
   - URL: https://ngxtension.dev/utilities/effects-side-effects/explicit-effect

8. **Signal + Observable 混在の最小橋渡し**
   - 目的: 全面RxJS化せず、必要箇所のみ合成。
   - 参考: `ngxtension derivedFrom`。
   - URL: https://ngxtension.dev/utilities/signal-async/derived-from

```ts
const page = signal(1);
const filters$ = new BehaviorSubject({ q: '' });
const query = derivedFrom({ page, filters: filters$ }, undefined, { initialValue: { page: 1, filters: { q: '' } } });
```

9. **「画面ローカルはsignal、ドメイン横断はstore」分離**
   - 目的: store肥大化防止。
   - 実務では `selectedId` や `isOpen` はコンポーネントsignal、
     認証/権限/共通キャッシュはstoreに置く。

10. **ステータスを文字列unionで固定（boolean乱立を避ける）**
```ts
type Status = 'idle' | 'loading' | 'reloading' | 'resolved' | 'error';
const status = signal<Status>('idle');
```

11. **latest-wins + abort の二重防御**
```ts
let controller: AbortController | null = null;
const seq = signal(0);
```
- 連打UI（検索、タブ切替）で特に有効。

12. **テンプレート側は `@if/@for` と signal読み取りを直結**
- Angular 18 control flowと組み合わせ、
  `@if (vm().loading) { ... } @else { ... }` を基本形にする。

### 15-3. 追加収集からの推奨
- lacolacoパターン（Signal of Signals）は Angular 18 で linkedSignal代替として有効。
- ただしチーム規約として「どの場面で使うか」を固定しないと可読性が落ちる。
- まずは **イベント駆動load + 3状態管理 + draft分離 + latest-wins** の4点を標準化し、
  次段階で store/utility（ngxtension, signalstory, ngrx-toolkit）を限定導入するのが安全。

---

## 16) さらに使われる「ハック寄り」実装（上級者向け）

> ここは可読性とのトレードオフが強い。チーム規約を決めて限定採用すること。

1. **TTL付きメモ化ローダー（key + ttlで再利用）**
```ts
const cache = signal<Record<string, { at: number; data: unknown }>>({});

async function loadWithTtl<T>(key: string, ttlMs: number, fetcher: () => Promise<T>) {
  const hit = cache()[key];
  if (hit && Date.now() - hit.at < ttlMs) return hit.data as T;
  const data = await fetcher();
  cache.update(prev => ({ ...prev, [key]: { at: Date.now(), data } }));
  return data;
}
```

2. **SWR（先にキャッシュ表示→裏で再取得）**
```ts
async function loadSWR<T>(key: string, fetcher: () => Promise<T>) {
  const stale = cache()[key]?.data as T | undefined;
  if (stale !== undefined) view.set(stale); // 先に表示
  const fresh = await fetcher();
  cache.update(prev => ({ ...prev, [key]: { at: Date.now(), data: fresh } }));
  view.set(fresh);
}
```

3. **single-flight（同一キーの重複リクエストを一本化）**
```ts
const inflight = new Map<string, Promise<unknown>>();

function singleFlight<T>(key: string, run: () => Promise<T>): Promise<T> {
  const p = inflight.get(key);
  if (p) return p as Promise<T>;
  const next = run().finally(() => inflight.delete(key));
  inflight.set(key, next);
  return next;
}
```

4. **Debounce付き手動検索（RxJSなし）**
```ts
let timer: ReturnType<typeof setTimeout> | null = null;
function scheduleSearch(ms = 300) {
  if (timer) clearTimeout(timer);
  timer = setTimeout(() => void onClickSearch(), ms);
}
```

5. **Undo/Redo（履歴stackをsignalで保持）**
```ts
const history = signal<ProjectDraft[]>([]);
const cursor = signal(-1);
```

6. **Patch Queue（保存APIを直列化）**
```ts
let queue = Promise.resolve();
function enqueueSave(task: () => Promise<void>) {
  queue = queue.then(task, task);
  return queue;
}
```

7. **Cross-tab同期（storageイベント + signal）**
```ts
window.addEventListener('storage', e => {
  if (e.key === 'draft') draft.set(JSON.parse(e.newValue ?? 'null'));
});
```

8. **Persisted Signal（localStorage backed）**
```ts
const theme = signal(localStorage.getItem('theme') ?? 'light');
function setTheme(v: string) {
  theme.set(v);
  localStorage.setItem('theme', v);
}
```

9. **Selector結果の弱参照キャッシュ（高コスト導出向け）**
```ts
const selectorCache = new WeakMap<object, unknown>();
```

10. **Lazy chunk state（画面表示時にだけsignalを生成）**
```ts
let advancedState: ReturnType<typeof signal<number>> | null = null;
function getAdvancedState() {
  return (advancedState ??= signal(0));
}
```

11. **Feature FlagでSignal/RxJS実装を切替**
```ts
const useSignalsPath = signal(true);
```

12. **エラー正規化レイヤー（UI側error型を統一）**
```ts
type UiError = { code: string; message: string };
function normalizeError(e: unknown): UiError { return { code: 'UNKNOWN', message: String(e) }; }
```

### 採用優先順位（推奨）
1. まずは section 9 の標準パターン。
2. 次に section 15 のlacolaco/GitHub由来パターン。
3. それでも不足する場合のみ本 section のハックを限定採用。
