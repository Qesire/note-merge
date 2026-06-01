# Vault Setup

Creating a new Obsidian PARA+Zettelkasten vault. Triggered by `init-vault`.

---

## Interactive Configuration Flow

When the user says `init-vault`, ask these questions in order. Do not proceed until each is answered.

### Q1: Vault path

```
"Vault 路径？" [默认: ~/KnowledgeBase]
```

If the path already exists and is not empty, warn and ask for confirmation.

### Q2: Research domains

```
"研究领域？（用逗号分隔，例如: quantization, diffusion, low-level-vision）"
```

Store in `note-merge.json` as `domains[]`. These drive:

- `2-Areas/<Domain>/` directory creation
- Keyword→directory mapping for classification
- `#area/<kebab-domain>` tags

### Q3: Source code repositories

```
"源码仓库路径？（用逗号分隔，例如: ~/TinyFusion, ~/DiTQuantValidation）
 这些路径用于 deepen 时搜索源码实现。"
```

Store in `note-merge.json` as `source_repos[]`. Do not verify paths exist at this point — user might create repos later.

### Q4: Primary language

```
"主要使用语言？"
  1) zh-CN（中文为主，文件名用中文）
  2) en（英文为主，文件名用 kebab-case）
  3) mixed（中英混排，按文件内容判断）
```

Store in `note-merge.json` as `language`.

---

## Directory Skeleton

After configuration, create:

```
<vault>/
├── .obsidian/
│   ├── app.json
│   ├── appearance.json
│   └── core-plugins.json
├── _MOCs/
│   ├── Home.md
│   ├── Code-Index.md
│   ├── Paper-Reading-List.md
│   └── Tag-Index.md
├── _templates/
│   └── (copied from skill templates/)
├── _attachments/
├── note-merge.json              ← written here
├── 0-Inbox/
│   ├── fleeting/
│   └── daily/
├── 1-Projects/
├── 2-Areas/
│   └── <each domain>/           ← per Q2
│       └── _index.md
├── 3-Resources/
│   ├── Papers/
│   ├── Code-Tools/
│   ├── Presentations/
│   └── Tutorials/
└── 4-Archives/
```

---

## .obsidian Config

### app.json

```json
{
  "newFileLocation": "folder",
  "newFileFolderPath": "0-Inbox/fleeting",
  "attachmentFolderPath": "_attachments",
  "alwaysUpdateLinks": true,
  "promptDelete": false
}
```

### core-plugins.json

Enable: file-explorer, global-search, graph, backlink, outgoing-link, tag-pane, page-preview, daily-notes, templates, note-composer, command-palette, markdown-importer, outline, word-count, file-recovery.

Disable: starred, random-note, zk-prefixer, slides, audio-recorder, workspaces, publish, sync.

### appearance.json

```json
{
  "baseFontSize": 16,
  "theme": "obsidian",
  "translucency": false
}
```

---

## _MOCs Initial Content

### Home.md

```markdown
---
tags: [type/moc, status/active]
created: <today>
---

# 知识库首页

## 项目 (1-Projects)

## 领域 (2-Areas)

## 最近笔记
```

### _index.md for each domain

For each domain D in `note-merge.json.domains[]`:

```markdown
---
tags: [type/moc, area/<kebab-D>]
created: <today>
---

# <D>

## 核心概念

## 子领域

## 关联项目

## 关键论文
```

---

## Templates Installation

Copy these from the skill's `templates/` directory into `<vault>/_templates/`:

| Template | For |
|----------|-----|
| `tpl-concept.md` | Draft concept notes |
| `tpl-concept-deepened.md` | Polished 5-layer concept notes |
| `tpl-paper-note.md` | Paper reading notes |
| `tpl-experiment.md` | Experiment logs |
| `tpl-project-index.md` | Project _index.md MOC |

The vault's existing templates in `~/.config/opencode/skills/note-merge/templates/` are copied as-is. If a vault-level `tpl-project-index.md` exists separately, keep it.

---

## Completion

After setup, report:

```
Vault initialized at: <path>
Domains: <list>
Source repos: <list>
Language: <lang>

Open in Obsidian:
  obsidian://open?vault=<vault-name>

  or: Obsidian app → Open folder as vault → <path>
```
