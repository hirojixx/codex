#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $0 <task_title> [search_query ...]"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLAN_DIR="$ROOT_DIR/research/logs/planning"
STAMP="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
TODAY="$(date -u +'%Y-%m-%d')"
TASK_TITLE="$1"
shift || true

slugify() {
  local input="$1"
  local slug
  slug="$(printf '%s' "$input" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"

  if [[ -z "$slug" ]]; then
    slug="task"
  fi

  printf '%s' "$slug"
}

TASK_SLUG="$(slugify "$TASK_TITLE")"
PLAN_LOG="$PLAN_DIR/${TODAY}__${TASK_SLUG}.md"

mkdir -p "$PLAN_DIR"
if [[ ! -f "$PLAN_LOG" ]]; then
  {
    echo "# Planning Log: $TASK_TITLE"
    echo
  } > "$PLAN_LOG"
elif [[ -s "$PLAN_LOG" ]]; then
  printf '\n' >> "$PLAN_LOG"
fi

{
  echo "## $STAMP"
  echo "- task: $TASK_TITLE"
  echo "- task_slug: $TASK_SLUG"
  echo "- planning_prompt: この作業の目的・成功条件・制約は何か？"
  echo "- pre_search:"
  if [[ "$#" -eq 0 ]]; then
    echo "  - (none)"
  else
    for q in "$@"; do
      echo "  - $q"
    done
  fi
  echo "- plan:"
  echo "  1. 要件整理"
  echo "  2. ファイル変更"
  echo "  3. 自己レビュー実行"
  echo "- status: planned ($TODAY)"
} >> "$PLAN_LOG"

echo "Planning entry appended to $PLAN_LOG"
