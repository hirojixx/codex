#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$ROOT_DIR/research/logs/self-review-log.md"
PLAN_LOG="$ROOT_DIR/research/logs/planning-log.md"
DATE_UTC="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
TODAY="$(date -u +'%Y-%m-%d')"

cd "$ROOT_DIR"

./scripts/reindex.sh >/dev/null

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
  echo "- reindex: passed"
  echo "- required-files: passed"
  echo "- planning-log-check: passed ($TODAY)"
  echo "- git-diff-summary:"
  git diff --stat
  echo
} >> "$LOG_FILE"

echo "Self review passed. Logged to $LOG_FILE"
