import { computed, Signal, signal, WritableSignal } from '@angular/core';

export type ResourceStatus = 'idle' | 'loading' | 'reloading' | 'resolved' | 'error';

export interface ResourceLikeState<T> {
  status: ResourceStatus;
  value: T | undefined;
  error: unknown;
  updatedAt: number | null;
}

/**
 * Angular 18向け resource 風ヘルパー。
 *
 * - effectを使わず、`load()` / `reload()` を明示呼び出し
 * - latest-wins（古いレスポンス破棄）
 * - AbortControllerでキャンセル可能
 */
export function createResourceLike<TParams, TValue>(options: {
  params: Signal<TParams>;
  loader: (params: TParams, ctx: { signal: AbortSignal }) => Promise<TValue>;
}) {
  const state = signal<ResourceLikeState<TValue>>({
    status: 'idle',
    value: undefined,
    error: null,
    updatedAt: null,
  });

  const latestSeq = signal(0);
  let controller: AbortController | null = null;

  const load = async () => {
    const seq = latestSeq() + 1;
    latestSeq.set(seq);

    controller?.abort();
    controller = new AbortController();

    state.update((prev) => ({
      ...prev,
      status: prev.value === undefined ? 'loading' : 'reloading',
      error: null,
    }));

    try {
      const data = await options.loader(options.params(), {
        signal: controller.signal,
      });

      // latest-wins
      if (seq !== latestSeq()) return;

      state.set({
        status: 'resolved',
        value: data,
        error: null,
        updatedAt: Date.now(),
      });
    } catch (err) {
      if (controller.signal.aborted) return;
      if (seq !== latestSeq()) return;

      state.update((prev) => ({
        ...prev,
        status: 'error',
        error: err,
      }));
    }
  };

  const reload = () => load();
  const abort = () => controller?.abort();

  return {
    state: state as WritableSignal<ResourceLikeState<TValue>>,
    status: computed(() => state().status),
    value: computed(() => state().value),
    error: computed(() => state().error),
    hasValue: computed(() => state().value !== undefined),
    isLoading: computed(
      () => state().status === 'loading' || state().status === 'reloading',
    ),
    load,
    reload,
    abort,
  };
}

// --------------------------------------------
// Usage sample: project detail resource-like
// --------------------------------------------

type ProjectDetail = { id: string; name: string; owner: string };

const selectedProjectId = signal<string | null>(null);

const detailResource = createResourceLike({
  params: selectedProjectId,
  loader: async (id, { signal }) => {
    if (!id) throw new Error('project id is null');

    const res = await fetch(`/api/projects/${id}`, { signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return (await res.json()) as ProjectDetail;
  },
});

export async function onSelectProject(id: string) {
  selectedProjectId.set(id);
  await detailResource.load();
}

export async function onRetry() {
  await detailResource.reload();
}
