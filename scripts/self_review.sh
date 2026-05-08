#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLAN_DIR="$ROOT_DIR/research/logs/planning"
REVIEW_DIR="$ROOT_DIR/research/logs/self-review"
DATE_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
TODAY="$(date -u +'%Y-%m-%d')"
TASK_TITLE="${1:-}"
STAGES=(00_inbox 01_active 02_reference 03_archive)
REINDEX_TARGETS="${REINDEX_TARGETS:-}"

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

latest_today_plan() {
  find "$PLAN_DIR" -maxdepth 1 -type f -name "${TODAY}__*.md" -print0 2>/dev/null \
    | xargs -0 -r stat -c '%Y %n' \
    | sort -nr \
    | sed -n '1s/^[0-9]\+ //p'
}

cd "$ROOT_DIR"

reindex_status="skipped (no stage changes detected)"
if [[ -n "$REINDEX_TARGETS" ]]; then
  # shellcheck disable=SC2086 # intentional word splitting for space-separated stage list.
  ./scripts/reindex.sh $REINDEX_TARGETS >/dev/null
  reindex_status="passed (${REINDEX_TARGETS})"
else
  changed_stages=()
  for stage in "${STAGES[@]}"; do
    stage_path="research/$stage"
    if ! git diff --quiet -- "$stage_path" \
      || ! git diff --cached --quiet -- "$stage_path" \
      || git ls-files --others --exclude-standard -- "$stage_path" | grep -q .; then
      changed_stages+=("$stage")
    fi
  done

  if [[ "${#changed_stages[@]}" -gt 0 ]]; then
    ./scripts/reindex.sh "${changed_stages[@]}" >/dev/null
    reindex_status="passed (${changed_stages[*]})"
  fi
fi

missing=0
for required in \
  "codex.md" \
  "research/_meta/taxonomy.md" \
  "research/_meta/update-policy.md" \
  "research/_templates/research-note.md" \
  "research/_templates/self-review-checklist.md" \
  "research/_templates/planning-brief.md" \
  "scripts/preplan.sh" \
  "scripts/reindex.sh" \
  "scripts/reindex_all.sh" \
  "scripts/self_review.sh"; do
  if [[ ! -f "$required" ]]; then
    echo "[ERROR] Missing required file: $required"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "Self review failed due to missing required files."
  exit 1
fi

if [[ -n "$TASK_TITLE" ]]; then
  TASK_SLUG="$(slugify "$TASK_TITLE")"
  PLAN_LOG="$PLAN_DIR/${TODAY}__${TASK_SLUG}.md"
else
  PLAN_LOG="$(latest_today_plan)"
  if [[ -n "$PLAN_LOG" ]]; then
    task_filename="$(basename "$PLAN_LOG")"
    TASK_SLUG="${task_filename#${TODAY}__}"
    TASK_SLUG="${TASK_SLUG%.md}"
  else
    TASK_SLUG=""
  fi
fi

if [[ -z "${PLAN_LOG:-}" ]] || [[ ! -f "$PLAN_LOG" ]] || ! grep -q "$TODAY" "$PLAN_LOG"; then
  echo "[ERROR] No task-specific planning log entry found for $TODAY. Run ./scripts/preplan.sh first."
  exit 1
fi

LOG_FILE="$REVIEW_DIR/${TODAY}__${TASK_SLUG}.md"
mkdir -p "$REVIEW_DIR"
if [[ ! -f "$LOG_FILE" ]]; then
  {
    echo "# Self Review Log: $TASK_SLUG"
    echo
  } > "$LOG_FILE"
elif [[ -s "$LOG_FILE" ]]; then
  printf '\n' >> "$LOG_FILE"
fi

{
  echo "## $DATE_UTC"
  echo "- task_slug: $TASK_SLUG"
  echo "- reindex: $reindex_status"
  echo "- required-files: passed"
  echo "- planning-log-check: passed ($PLAN_LOG)"
  echo "- git-diff-summary:"
  git diff --stat HEAD
} >> "$LOG_FILE"

echo "Self review passed. Logged to $LOG_FILE"
