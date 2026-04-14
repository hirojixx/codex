import {
  computed,
  input,
  Signal,
  signal,
  WritableSignal,
} from '@angular/core';

/**
 * Angular 18向け linkedSignal 風ヘルパー。
 *
 * Zenn記事で紹介されている「computedの中でsignalを作る」パターンを
 * 関数化し、返却値を WritableSignal<T> に寄せる。
 */
export function linkedSignalLike<TSource, TValue>(options: {
  source: Signal<TSource>;
  computation: (source: TSource) => TValue;
}): WritableSignal<TValue> {
  const innerWritable = computed(() => {
    const source = options.source();
    return signal<TValue>(options.computation(source));
  });

  const linked = (() => innerWritable()()) as WritableSignal<TValue>;

  linked.set = (value) => {
    innerWritable().set(value);
  };

  linked.update = (updater) => {
    innerWritable().update(updater);
  };

  linked.asReadonly = () => computed(() => linked());

  return linked;
}

// --------------------------------------------
// Usage sample (from requested pattern)
// --------------------------------------------

const initialOptions = ['apple', 'banana', 'cheese'];

export class FavoriteFoodSelector {
  options = input(initialOptions);

  // source(options) が変わると新しい writable signal に置き換わる
  selectedFood = linkedSignalLike({
    source: this.options,
    computation: (): string | null => null,
  });

  selectFood(food: string) {
    this.selectedFood.set(food);
  }
}

// --------------------------------------------
// Usage sample: sidebar list + project detail edit
// --------------------------------------------

type Project = {
  id: string;
  name: string;
  owner: string;
  description: string;
};

const selectedProjectId = signal<string | null>(null);
const projectDetailById = signal<Record<string, Project>>({});

const selectedProject = computed<Project | null>(() => {
  const id = selectedProjectId();
  if (!id) return null;
  return projectDetailById()[id] ?? null;
});

const projectDraft = linkedSignalLike<Project | null, Project | null>({
  source: selectedProject,
  computation: (source) => (source ? structuredClone(source) : null),
});

export async function onSelectProject(
  id: string,
  fetchDetail: (id: string) => Promise<Project>,
) {
  selectedProjectId.set(id);

  if (!projectDetailById()[id]) {
    const detail = await fetchDetail(id);
    projectDetailById.update((prev) => ({ ...prev, [id]: detail }));
  }

  // 読み取り時に最新のinner signalへアクセス
  projectDraft();
}

export function onEditName(name: string) {
  const draft = projectDraft();
  if (!draft) return;
  projectDraft.set({ ...draft, name });
}

export async function onSaveProject(save: (p: Project) => Promise<Project>) {
  const draft = projectDraft();
  if (!draft) return;

  const saved = await save(draft);
  projectDetailById.update((prev) => ({ ...prev, [saved.id]: saved }));

  // source更新後、次回 read で draft 再生成
  projectDraft();
}
