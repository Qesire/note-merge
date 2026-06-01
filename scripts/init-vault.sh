#!/usr/bin/env bash
# init-vault.sh — Create a new Obsidian PARA+Zettelkasten vault
# Usage: ./init-vault.sh [vault_path]
# Default: ~/KnowledgeBase

set -euo pipefail

VAULT="${1:-$HOME/KnowledgeBase}"

if [ -d "$VAULT" ] && [ "$(ls -A "$VAULT" 2>/dev/null)" ]; then
    echo "WARNING: $VAULT already exists and is not empty."
    echo -n "Continue anyway? This will only create missing dirs/files. [y/N] "
    read -r REPLY
    if [ "$REPLY" != "y" ] && [ "$REPLY" != "Y" ]; then
        echo "Aborted."
        exit 0
    fi
fi

echo "==> Initializing Obsidian vault at: $VAULT"

mkdir -p "$VAULT"/{.obsidian,_MOCs,_templates,_attachments}
mkdir -p "$VAULT"/0-Inbox/{fleeting,daily}
mkdir -p "$VAULT"/1-Projects
mkdir -p "$VAULT"/2-Areas
mkdir -p "$VAULT"/3-Resources/{Papers,Code-Tools,Presentations,Tutorials}
mkdir -p "$VAULT"/4-Archives

cat > "$VAULT/.obsidian/app.json" << 'EOF'
{
  "newFileLocation": "folder",
  "newFileFolderPath": "0-Inbox/fleeting",
  "attachmentFolderPath": "_attachments",
  "alwaysUpdateLinks": true,
  "promptDelete": false
}
EOF

cat > "$VAULT/.obsidian/core-plugins.json" << 'EOF'
{
  "file-explorer": true,
  "global-search": true,
  "graph": true,
  "backlink": true,
  "outgoing-link": true,
  "tag-pane": true,
  "page-preview": true,
  "daily-notes": true,
  "templates": true,
  "note-composer": true,
  "command-palette": true,
  "markdown-importer": true,
  "outline": true,
  "word-count": true,
  "file-recovery": true,
  "starred": false,
  "random-note": false,
  "zk-prefixer": false,
  "slides": false,
  "audio-recorder": false,
  "workspaces": false,
  "publish": false,
  "sync": false
}
EOF

cat > "$VAULT/.obsidian/appearance.json" << 'EOF'
{
  "baseFontSize": 16,
  "theme": "obsidian",
  "translucency": false
}
EOF

for D in "$VAULT"/_MOCs "$VAULT"/0-Inbox/fleeting "$VAULT"/0-Inbox/daily \
         "$VAULT"/1-Projects "$VAULT"/2-Areas "$VAULT"/3-Resources/Papers \
         "$VAULT"/3-Resources/Code-Tools "$VAULT"/3-Resources/Presentations \
         "$VAULT"/3-Resources/Tutorials "$VAULT"/4-Archives \
         "$VAULT"/_attachments "$VAULT"/_templates; do
    touch "$D/.gitkeep" 2>/dev/null || true
done

cat > "$VAULT/_MOCs/Home.md" << 'EOF'
---
tags: [type/moc, status/active]
created: $(date +%Y-%m-%d)
---

# 知识库首页

## 项目 (1-Projects)

## 领域 (2-Areas)

## 最近笔记
EOF

cat > "$VAULT/_MOCs/Code-Index.md" << 'EOF'
---
tags: [type/moc, repo]
created: $(date +%Y-%m-%d)
---

# 代码索引

| 仓库 | 项目 | 语言 | 路径 |
|------|------|------|------|
EOF

cat > "$VAULT/_MOCs/Paper-Reading-List.md" << 'EOF'
---
tags: [type/moc, type/paper]
created: $(date +%Y-%m-%d)
---

# 论文阅读清单

## 待读

## 已读

## 与项目关联
EOF

cat > "$VAULT/_MOCs/Tag-Index.md" << 'EOF'
---
tags: [type/moc]
created: $(date +%Y-%m-%d)
---

# 标签索引

## type

## area

## technique

## status
EOF

if [ -d "$(dirname "$0")/../templates" ]; then
    echo "==> Copying templates from $(dirname "$0")/../templates/"
    cp "$(dirname "$0")/../templates"/*.md "$VAULT/_templates/" 2>/dev/null || true
    echo "    Templates copied: $(ls "$VAULT/_templates"/*.md 2>/dev/null | wc -l) files"
fi

echo ""
echo "Vault initialized successfully!"
echo "Open it in Obsidian:"
echo "  obsidian://open?vault=$(basename "$VAULT")"
echo ""
echo "  or from Obsidian app: Open folder as vault → $VAULT"
