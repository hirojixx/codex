#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$ROOT_DIR/research/logs/self-review-log.md"
PLAN_LOG="$ROOT_DIR/research/logs/planning-log.md"
DATE_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
TODAY="$(date -u +'%Y-%m-%d')"
STAGES=(00_inbox 01_active 02_reference 03_archive)
REINDEX_TARGETS="${REINDEX_TARGETS:-}"

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
  "scripts/preplan.sh"; do
  if [[ ! -f "$required" ]]; then
    echo "[ERROR] Missing required file: $required"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "Self review failed due to missing required files."
  exit 1
fi

if [[ ! -f "$PLAN_LOG" ]] || ! grep -q "$TODAY" "$PLAN_LOG"; then
  echo "[ERROR] No planning log entry found for $TODAY. Run ./scripts/preplan.sh first."
  exit 1
fi

{
  echo "## $DATE_UTC"
  echo "- reindex: $reindex_status"
  echo "- required-files: passed"
  echo "- planning-log-check: passed ($TODAY)"
  echo "- git-diff-summary:"
  git diff --stat
  echo
} >> "$LOG_FILE"

echo "Self review passed. Logged to $LOG_FILE"
