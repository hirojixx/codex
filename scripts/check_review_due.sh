#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TODAY="${REVIEW_DUE_TODAY:-$(date -u +'%Y-%m-%d')}"
WARNING_DAYS="${REVIEW_DUE_WARNING_DAYS:-7}"

cd "$ROOT_DIR"

if ! [[ "$TODAY" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "[ERROR] REVIEW_DUE_TODAY must be YYYY-MM-DD: $TODAY" >&2
  exit 1
fi

if ! [[ "$WARNING_DAYS" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] REVIEW_DUE_WARNING_DAYS must be a non-negative integer: $WARNING_DAYS" >&2
  exit 1
fi

today_epoch="$(date -u -d "$TODAY" +%s)"
warning_seconds=$((WARNING_DAYS * 86400))
status=0
checked=0

while IFS= read -r -d '' file; do
  checked=$((checked + 1))

  review_due="$(awk '
    NR == 1 { next }
    /^## / { exit }
    /^---$/ { exit }
    /^[[:space:]]*-[[:space:]]*review_due:[[:space:]]*/ {
      line = $0
      sub(/^[[:space:]]*-[[:space:]]*review_due:[[:space:]]*/, "", line)
      sub(/[[:space:]]*#.*/, "", line)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      print line
      exit
    }
  ' "$file")"

  if [[ -z "$review_due" ]]; then
    echo "[ERROR] Missing review_due metadata: $file"
    status=1
    continue
  fi

  if ! [[ "$review_due" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || ! due_epoch="$(date -u -d "$review_due" +%s 2>/dev/null)"; then
    echo "[ERROR] Invalid review_due metadata in $file: $review_due"
    status=1
    continue
  fi

  delta=$((due_epoch - today_epoch))
  if (( delta < 0 )); then
    echo "[ERROR] review_due is past due in $file: $review_due (today: $TODAY)"
    status=1
  elif (( delta <= warning_seconds )); then
    days_remaining=$((delta / 86400))
    echo "[WARN] review_due is within ${WARNING_DAYS} days in $file: $review_due (${days_remaining} days remaining)"
  fi
done < <(find research -path 'research/[0-9][0-9]_*/*.md' -type f -print0 | sort -z)

if (( checked == 0 )); then
  echo "[WARN] No research note files found under research/[0-9][0-9]_*/"
fi

exit "$status"
