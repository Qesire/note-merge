#!/usr/bin/env bash
# tag-inventory.sh — List all tags used in the vault with counts
# Usage: ./tag-inventory.sh [vault_path]
# Default: ~/KnowledgeBase

set -euo pipefail

VAULT="${1:-$HOME/KnowledgeBase}"
TMPFILE=$(mktemp)

echo "=== Tag Inventory ==="
echo "Vault: $VAULT"
echo ""

cleanup() { rm -f "$TMPFILE"; }
trap cleanup EXIT

while IFS= read -r -d '' file; do
    sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null | \
        grep -oP '#[a-zA-Z0-9_/-]+' 2>/dev/null || true
done < <(find "$VAULT" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/_templates/*" -print0 2>/dev/null) > "$TMPFILE"

sort "$TMPFILE" | uniq -c | sort -rn | while read -r count tag; do
    printf "  %4d  %s\n" "$count" "$tag"
done

echo ""
TOTAL_TAGS=$(wc -l < "$TMPFILE")
UNIQUE_TAGS=$(sort "$TMPFILE" | uniq | wc -l)
echo "Total tag occurrences: $TOTAL_TAGS"
echo "Unique tags: $UNIQUE_TAGS"
