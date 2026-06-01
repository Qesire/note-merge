#!/usr/bin/env bash
# scan-stale-drafts.sh — Find draft notes not modified in >30 days
# Usage: ./scan-stale-drafts.sh [vault_path] [days_threshold]
# Default: ~/KnowledgeBase, 30 days

set -euo pipefail

VAULT="${1:-$HOME/KnowledgeBase}"
DAYS="${2:-30}"
STALE=0

echo "=== Stale Drafts (>$DAYS days) ==="
echo "Vault: $VAULT"
echo ""

while IFS= read -r -d '' file; do
    relpath="${file#$VAULT/}"

    if ! grep -q '#status/draft' "$file" 2>/dev/null && \
       ! grep -q 'status/draft' "$file" 2>/dev/null; then
        continue
    fi

    last_mod=$(stat -c %Y "$file" 2>/dev/null || echo 0)
    now=$(date +%s)
    age_days=$(( (now - last_mod) / 86400 ))

    if [ "$age_days" -gt "$DAYS" ]; then
        mdate=$(date -d "@$last_mod" "+%Y-%m-%d" 2>/dev/null || echo "unknown")
        echo "  STALE: $relpath (last modified: $mdate, age: ${age_days}d)"
        STALE=$((STALE + 1))
    fi
done < <(find "$VAULT" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/_templates/*" -print0 2>/dev/null)

echo ""
echo "Stale drafts found: $STALE"
if [ "$STALE" -eq 0 ]; then
    echo "No stale drafts."
fi
