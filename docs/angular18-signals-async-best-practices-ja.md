# Angular 18 Signals + 非同期処理 実践ガイド（再構成版）

最終更新: 2026-04-14  
PR再作成: 2026-04-14  
対象: Angular 18（`linkedSignal` / `resource` 非前提）

---

## 0. このドキュメントの目的

この資料は、以下を**分類して**すぐ使える形に整理する。

1. 設計原則（何をどこに置くか）
2. 非同期状態モデル（ロード/エラー/競合対策）
3. Angular 18での `linkedSignal` / `resource` 代替
4. 実装パターン（標準）
5. 実装パターン（ハック寄り）
6. アンチパターン

---

## 1. まず最初に決めること（意思決定マトリクス）

| 問題 | 第一選択 | 補助 | 備考 |
|---|---|---|---|
| 画面ローカル状態 | `signal` | `computed` | `selectedId`, 開閉状態など |
| 画面表示用の導出 | `computed` | - | 編集用の元にしない |
| APIロード | イベント駆動 `async/await` | `firstValueFrom` | effect起点ロードを避ける |
| 外部副作用（storage/log） | `effect` | helper化 | state伝播用途では使わない |
| 編集フォーム | `base + draft` 二層 | `structuredClone` | readonly/computed問題回避 |
| 複雑な非同期合成 | RxJS（限定） | `toSignal` | キャンセル/合流/再試行が複雑なとき |

---

## 2. 推奨アーキテクチャ（サイドバー一覧 + 右詳細）

### 2-1. 状態分類

- **Server cache state**
  - `listState`
  - `detailsById`
- **UI state**
  - `selectedId`
  - `isPaneOpen`
- **Edit state**
  - `draftById` または `currentDraft`

### 2-2. 非同期フロー（標準）

1. 初期表示: 一覧を `loadList()`
2. 一覧選択: `selectedId.set(id)`
3. 詳細未取得なら `loadDetail(id)`
4. 編集開始で `draft` を base から生成
5. 保存で cache 更新 + draft 再同期

---

## 3. 変更検知の要点（`set` したのに更新されない問題）

Angular Signal は既定で `Object.is` ベース。  
以下は更新されない原因になりやすい。

- 同一参照の再セット（破壊的更新）
- templateで signal を呼ばずに参照
- 依存を `untracked` で外している
- `equal` 関数を厳しくしすぎた

**対策**
- 不変更新（新しい参照を返す）
- template側で `sig()` を読む
- `equal` は最小限

---

## 4. Angular 18 での `linkedSignal` 代替（標準）

`docs/examples/linked-signal-like.sample.ts` に実装済み。

- `linkedSignalLike<TSource, TValue>()` を提供
- `WritableSignal<TValue>` を返す
- `computed(() => signal(...))` パターンで source変更時に内側signal再生成
- `effect` 不要

この方式は lacolaco 氏の解説パターン（Signal of Signals）と同系統。

---

## 5. Angular 18 での `resource` 代替（標準）

`docs/examples/resource-like.sample.ts` に実装済み。

- `createResourceLike<TParams, TValue>()`
- `status/value/error/isLoading/hasValue`
- `load() / reload() / abort()`
- latest-wins + AbortController

> 注: v19+ `resource` の完全互換ではなく、Angular 18向けの「resource風」。

---

## 6. 標準パターン集（まず採用する12個）

### A. ロード制御
1. イベント駆動ロード
2. id別キャッシュ
3. latest-wins
4. 3状態管理（data/loading/error）

### B. 編集・保存
5. `base + draft` 二層
6. 楽観更新 + 失敗時ロールバック
7. id単位部分更新
8. dirty判定 `computed`

### C. 検索・再取得
9. 検索語signal + 明示検索
10. TTL/lastFetchedAt 再取得
11. ページ離脱時 reset
12. 共通ローダー `loadByKey`

> 各最小サンプルは section 6-1 を参照。

### 6-1. 最小コード断片（標準12）

```ts
// 1) event-driven load
async function selectProject(id: string) {
  selectedId.set(id);
  if (!detailsById()[id]) {
    const d = await fetchProjectDetail(id);
    detailsById.update(prev => ({ ...prev, [id]: d }));
  }
}

// 3) latest-wins
const seq = signal(0);
async function loadLatest(id: string) {
  const n = seq() + 1;
  seq.set(n);
  const d = await fetchProjectDetail(id);
  if (n !== seq()) return;
  detailsById.update(prev => ({ ...prev, [id]: d }));
}

// 5) base + draft
const base = computed(() => detailsById()[selectedId() ?? ''] ?? null);
const draft = signal<ProjectDetail | null>(null);
function resetDraft() {
  draft.set(base() ? structuredClone(base()!) : null);
}

// 8) dirty
const isDirty = computed(() => JSON.stringify(base()) !== JSON.stringify(draft()));
```

---

## 7. ハック寄りパターン（必要時のみ）

> 以下は「標準で困った時にだけ」採用する。全項目に最小サンプルを示す。

### 7-1. lacolaco由来（3）

1) Signal of Signals（`computed(() => signal(...))`）
```ts
const selectedFood = computed(() => {
  options();
  return signal<string | null>(null);
});

function selectFood(food: string) {
  selectedFood().set(food);
}
```

2) effect内同期write回避（導出はcomputedへ）
```ts
const fullName = computed(() => `${firstName()} ${lastName()}`);
// effectの中で別signalへ set しない
```

3) input/output + Signal 境界運用
```ts
// parent
<child [userId]="selectedId()" (saved)="reload()" />

// child
userId = input.required<string>();
saved = output<void>();
```

### 7-2. GitHub / Ecosystem由来（9）

4) fetch + signal軽量ローダー
```ts
const loading = signal(false);
const data = signal<Item[]>([]);
async function load() {
  loading.set(true);
  data.set(await fetch('/api/items').then(r => r.json()));
  loading.set(false);
}
```

5) Signal Store段階導入（service内signalから移行）
```ts
@Injectable()
export class ProjectState {
  readonly projects = signal<Project[]>([]);
  readonly selectedId = signal<string | null>(null);
}
```

6) immutable強制（mutation防止）
```ts
function addItem(next: Item) {
  items.update(prev => [...prev, next]); // push禁止
}
```

7) `explicitEffect` で依存明示
```ts
explicitEffect([selectedId, filters], ([id, f]) => {
  console.log('track only explicit deps', id, f);
});
```

8) `derivedFrom` で Signal+Observable 橋渡し
```ts
const query = derivedFrom({ page, filters: filters$ }, undefined, {
  initialValue: { page: 1, filters: { q: '' } },
});
```

9) 画面ローカルsignal / 横断store分離
```ts
// component local
const isOpen = signal(false);
// app-wide store
authStore.user();
```

10) status を union で固定
```ts
type Status = 'idle' | 'loading' | 'reloading' | 'resolved' | 'error';
const status = signal<Status>('idle');
```

11) latest-wins + abort 二重防御
```ts
const seq = signal(0);
let controller: AbortController | null = null;
```

12) `@if/@for` と signal読取直結
```html
@if (vm().loading) { <spinner /> }
@else { @for (item of vm().items; track item.id) { <li>{{item.name}}</li> } }
```

### 7-3. さらに上級ハック（12）

13) TTLメモ化ローダー
```ts
const cache = signal<Record<string, { at: number; data: unknown }>>({});
```

14) SWR（stale即表示 + 背景更新）
```ts
if (cache()[key]) view.set(cache()[key].data as T);
view.set(await fetcher());
```

15) single-flight（同キー重複排除）
```ts
const inflight = new Map<string, Promise<unknown>>();
```

16) RxJSなし debounce
```ts
let timer: ReturnType<typeof setTimeout> | null = null;
```

17) Undo/Redo 履歴stack
```ts
const history = signal<ProjectDraft[]>([]);
const cursor = signal(-1);
```

18) patch queue（保存直列化）
```ts
let queue = Promise.resolve();
queue = queue.then(() => saveApi(draft()));
```

19) cross-tab 同期
```ts
window.addEventListener('storage', e => {
  if (e.key === 'draft') draft.set(JSON.parse(e.newValue ?? 'null'));
});
```

20) persisted signal
```ts
const theme = signal(localStorage.getItem('theme') ?? 'light');
```

21) selector弱参照キャッシュ
```ts
const selectorCache = new WeakMap<object, unknown>();
```

22) lazy state 初期化
```ts
let advanced: WritableSignal<number> | null = null;
const getAdvanced = () => (advanced ??= signal(0));
```

23) feature flag で Signal/RxJS 切替
```ts
const useSignalsPath = signal(true);
```

24) error正規化レイヤー
```ts
type UiError = { code: string; message: string };
const normalizeError = (e: unknown): UiError => ({ code: 'UNKNOWN', message: String(e) });
```

---

## 8. アンチパターン（分類）

### A. リアクティブ設計ミス
- effectでAPI連鎖実行
- effect内`set`で状態伝播
- computedを編集元にしようとする

### B. イミュータブル違反
- 配列/objectを破壊的更新
- 同一参照を再セット

### C. 非同期制御不足
- request競合未対策
- loading/error未管理
- 毎回フル再取得

### D. アーキテクチャ過剰
- 巨大signal一枚岩
- RxJS完全排除で逆に複雑化
- `toSignal` の作り直し多重購読

---

## 9. 採用順序（チーム運用用）

1. **標準12パターンを規約化**（section 6）
2. `linkedSignalLike` / `resourceLike` を共通ユーティリティ化
3. 必要箇所だけ RxJS を許可（キャンセル/合流/再試行）
4. それでも不足した箇所だけ section 7 のハックを採用

---

## 10. 参照（一次情報・実装系）

### lacolaco
- https://zenn.dev/lacolaco/articles/angular-v19-linked-signal
- https://zenn.dev/lacolaco/articles/angular-v19-effect-changes
- https://zenn.dev/lacolaco/articles/angular-signals-and-component-communication

### Angular18/GitHub/Ecosystem
- https://github.com/nicetomytyuk/angular-18-fetch-signals-example
- https://github.com/zuriscript/signalstory
- https://github.com/markostanimirovic/ngrx-signal-store-playground
- https://github.com/angular-architects/ngrx-toolkit
- https://ngxtension.dev/utilities/effects-side-effects/explicit-effect
- https://ngxtension.dev/utilities/signal-async/derived-from

### このリポジトリ内サンプル
- `docs/examples/linked-signal-like.sample.ts`
- `docs/examples/resource-like.sample.ts`
