#!/usr/bin/env bash
# migrate-status.sh — Batch-update #status/* tags across vault notes
# Usage: ./migrate-status.sh <from_status> <to_status> [vault_path] [--dry-run]
# Example: ./migrate-status.sh draft archived ~/KnowledgeBase --dry-run

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <from_status> <to_status> [vault_path] [--dry-run]"
    echo "Example: $0 draft archived ~/KnowledgeBase --dry-run"
    echo "Example: $0 stub draft           (updates default vault, writes changes)"
    exit 1
fi

FROM="$1"
TO="$2"
VAULT="${3:-$HOME/KnowledgeBase}"
DRY_RUN=false

if [ "${4:-}" = "--dry-run" ] || [ "${3:-}" = "--dry-run" ]; then
    DRY_RUN=true
fi

FROM_TAG="status/${FROM}"
TO_TAG="status/${TO}"

echo "=== Status Migration: $FROM_TAG → $TO_TAG ==="
echo "Vault: $VAULT"
if $DRY_RUN; then echo "MODE: DRY RUN (no files will be modified)"; fi
echo ""

CHANGED=0
TOTAL_CHECKED=0

while IFS= read -r -d '' file; do
    TOTAL_CHECKED=$((TOTAL_CHECKED + 1))
    if grep -q "$FROM_TAG" "$file" 2>/dev/null; then
        relpath="${file#$VAULT/}"
        echo "  UPDATE: $relpath"
        CHANGED=$((CHANGED + 1))

        if ! $DRY_RUN; then
            cp "$file" "$file.bak"
            sed -i "s/$FROM_TAG/$TO_TAG/g" "$file"
        fi
    fi
done < <(find "$VAULT" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/_templates/*" -print0 2>/dev/null)

echo ""
echo "Files checked: $TOTAL_CHECKED"
echo "Files to change: $CHANGED"

if ! $DRY_RUN && [ $CHANGED -gt 0 ]; then
    echo "Changes applied. Backup files created as *.bak"
    echo "Run 'find \"$VAULT\" -name \"*.md.bak\" -delete' to clean up after verification."
fi
