#!/usr/bin/env bash
# validate-frontmatter.sh — Scan vault .md files for missing/invalid frontmatter
# Usage: ./validate-frontmatter.sh [vault_path]
# Default: ~/KnowledgeBase

set -euo pipefail

VAULT="${1:-$HOME/KnowledgeBase}"
ISSUES=0
TOTAL=0

echo "=== Frontmatter Validation ==="
echo "Vault: $VAULT"
echo ""

while IFS= read -r -d '' file; do
    TOTAL=$((TOTAL + 1))
    filename=$(basename "$file")
    relpath="${file#$VAULT/}"
    issues=0

    firstline=$(head -1 "$file")
    if [ "$firstline" != "---" ]; then
        echo "  MISSING frontmatter: $relpath"
        ISSUES=$((ISSUES + 1))
        continue
    fi

    frontmatter=$(sed -n '2,/^---$/p' "$file" | head -50)

    if ! echo "$frontmatter" | grep -q '^tags:'; then
        echo "  MISSING tags: $relpath"
        issues=$((issues + 1))
    fi

    if ! echo "$frontmatter" | grep -q '^created:'; then
        echo "  MISSING created: $relpath"
        issues=$((issues + 1))
    fi

    if [ "$issues" -gt 0 ]; then
        ISSUES=$((ISSUES + 1))
    fi
done < <(find "$VAULT" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/_templates/*" -print0 2>/dev/null)

echo ""
echo "----------------------------------------"
echo "Total .md files scanned: $TOTAL"
echo "Files with issues:       $ISSUES"
if [ "$TOTAL" -gt 0 ]; then
    pct=$((100 - ISSUES * 100 / TOTAL))
    echo "Compliance rate:         $pct%"
fi
if [ "$ISSUES" -eq 0 ]; then
    echo "All frontmatter valid."
fi
