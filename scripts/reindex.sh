#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_FILE="$ROOT_DIR/research/_meta/index.md"

{
  echo "# Research Index"
  echo
  echo "Generated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  echo

  for section in 00_inbox 01_active 02_reference 03_archive; do
    echo "## ${section}"
    found=0
    section_dir="$ROOT_DIR/research/$section"

    if [[ -d "$section_dir" ]]; then
      while IFS= read -r file; do
        found=1
        rel="${file#$ROOT_DIR/}"
        echo "- ${rel}"
      done < <(find "$section_dir" -maxdepth 1 -type f -name '*.md' | sort)
    fi

    if [[ "$found" -eq 0 ]]; then
      echo "- (empty)"
    fi

    echo
  done
} > "$OUT_FILE"

echo "Wrote $OUT_FILE"
