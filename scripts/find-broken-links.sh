#!/usr/bin/env bash
# find-broken-links.sh — Find broken [[wikilinks]] in the vault
# Usage: ./find-broken-links.sh [vault_path]
# Default: ~/KnowledgeBase

set -euo pipefail

VAULT="${1:-$HOME/KnowledgeBase}"
BROKEN=0

echo "=== Broken Wikilink Check ==="
echo "Vault: $VAULT"
echo ""

while IFS= read -r -d '' file; do
    relpath="${file#$VAULT/}"
    filename=$(basename "$file" .md)

    grep -noP '\[\[[^\[\]\|#]+' "$file" 2>/dev/null | while IFS=: read -r line link; do
        target=$(echo "$link" | sed 's/^\[\[//' | sed 's/[|#].*//' | xargs)

        [ -z "$target" ] && continue
        if [ "$target" = "$filename" ]; then
            continue
        fi

        found=0
        if [ -f "$(dirname "$file")/$target.md" ]; then
            found=1
        elif [ -f "$VAULT/$target.md" ]; then
            found=1
        elif [ -f "$VAULT/0-Inbox/$target.md" ] || \
             [ -f "$VAULT/1-Projects/$target.md" ] || \
             [ -f "$VAULT/2-Areas/$target.md" ] || \
             [ -f "$VAULT/3-Resources/$target.md" ]; then
            found=1
        else
            target_found=$(find "$VAULT" -name "${target}.md" -not -path "*/.obsidian/*" -not -path "*/_templates/*" 2>/dev/null | head -1)
            if [ -n "$target_found" ]; then
                found=1
            fi
        fi

        if [ "$found" -eq 0 ]; then
            echo "  BROKEN: $relpath:$line → [[$target]]"
            BROKEN=$((BROKEN + 1))
        fi
    done
done < <(find "$VAULT" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/_templates/*" -print0 2>/dev/null)

echo ""
echo "Broken links found: $BROKEN"
if [ "$BROKEN" -eq 0 ]; then
    echo "All wikilinks valid."
fi
