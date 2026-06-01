#!/usr/bin/env bash
# check-moc-coverage.sh — Find notes missing from their parent _index.md MOC
# Usage: ./check-moc-coverage.sh [vault_path]
# Default: ~/KnowledgeBase

set -euo pipefail

VAULT="${1:-$HOME/KnowledgeBase}"
MISSING_TOTAL=0

echo "=== MOC Coverage Check ==="
echo "Vault: $VAULT"
echo ""

for dir in "$VAULT"/1-Projects/*/ "$VAULT"/2-Areas/*/; do
    [ -d "$dir" ] || continue
    dirname=$(basename "$dir")
    moc="$dir/_index.md"

    if [ ! -f "$moc" ]; then
        echo "  MISSING _index.md: ${dir#$VAULT/}"
        continue
    fi

    while IFS= read -r -d '' note; do
        notebase=$(basename "$note" .md)
        [ "$notebase" = "_index" ] && continue

        if ! grep -q "\[\[$notebase" "$moc" 2>/dev/null && \
           ! grep -q "\[\[${notebase/ /-}" "$moc" 2>/dev/null; then
            echo "  NOT IN MOC: ${note#$VAULT/} (missing from ${moc#$VAULT/})"
            MISSING_TOTAL=$((MISSING_TOTAL + 1))
        fi
    done < <(find "$dir" -maxdepth 2 -name "*.md" -not -name "_index.md" -print0 2>/dev/null)
done

echo ""
echo "Notes missing from MOC files: $MISSING_TOTAL"
if [ "$MISSING_TOTAL" -eq 0 ]; then
    echo "All notes properly indexed in MOC files."
fi
