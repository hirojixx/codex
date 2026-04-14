#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $0 <task_title> [search_query ...]"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLAN_LOG="$ROOT_DIR/research/logs/planning-log.md"
STAMP="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
TODAY="$(date -u +'%Y-%m-%d')"
TASK_TITLE="$1"
shift || true

mkdir -p "$(dirname "$PLAN_LOG")"
if [[ ! -f "$PLAN_LOG" ]]; then
  {
    echo "# Planning Log"
    echo
  } > "$PLAN_LOG"
fi

{
  echo "## $STAMP"
  echo "- task: $TASK_TITLE"
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
  echo
} >> "$PLAN_LOG"

echo "Planning entry appended to $PLAN_LOG"
