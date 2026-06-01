# Obsidian Vault Setup

Detailed instructions for creating a PARA+Zettelkasten Obsidian vault from scratch.

---

## Creating a Vault in Obsidian

### Via Obsidian App (GUI)

1. Open Obsidian → click "Open another vault" (bottom-left)
2. Click "Create new vault"
3. Name: `KnowledgeBase`, Location: `~` (home directory)
4. After creation: Settings → Files & Links → set:
   - "Default location for new notes": "In the folder specified below"
   - "Folder to create new notes in": `0-Inbox/fleeting`
   - "Attachment folder path": `_attachments`
   - Turn ON "Automatically update internal links"

### Via `init-vault` (skill action)

```
init-vault [path]
```

If no path given, defaults to `~/KnowledgeBase/`. This creates all directories, writes `.obsidian/` config, and injects templates. No Obsidian app required for initialization — it just creates the directory structure and config files.

---

## Directory Skeleton

```
~/KnowledgeBase/
├── .obsidian/
│   ├── app.json
│   ├── appearance.json
│   └── core-plugins.json
├── _MOCs/
│   ├── Home.md                  # Vault home / dashboard
│   ├── Code-Index.md            # All codebases across projects
│   ├── Paper-Reading-List.md    # Aggregated paper references
│   └── Tag-Index.md             # Tag-based index
├── _templates/
│   ├── tpl-concept.md
│   ├── tpl-concept-deepened.md
│   ├── tpl-paper-note.md
│   ├── tpl-experiment.md
│   ├── tpl-project-index.md
│   ├── tpl-area-index.md
│   ├── tpl-daily.md
│   ├── tpl-codebase.md
│   ├── tpl-stub.md
│   └── tpl-chat-extract.md
├── _attachments/                # Images, PDFs, etc.
├── 0-Inbox/
│   ├── fleeting/                # Uncategorized quick captures
│   └── daily/                   # Daily journal entries
├── 1-Projects/                  # Active projects
│   └── <ProjectName>/
│       ├── _index.md            # Project MOC
│       ├── Codebase.md          # Codebase map
│       ├── methods/             # Method/algorithm notes
│       └── experiments/         # Experiment logs
├── 2-Areas/                     # Research areas (long-term)
│   └── <AreaName>/
│       ├── _index.md            # Area MOC
│       └── <Concept>.md         # Atomic concept notes
├── 3-Resources/                 # Reference material
│   ├── Papers/
│   │   └── <topic>/            # Paper notes organized by topic
│   ├── Code-Tools/
│   ├── Presentations/
│   └── Tutorials/
└── 4-Archives/                  # Completed/archived projects
```

---

## .obsidian Config Files

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

```json
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
```

### appearance.json

```json
{
  "baseFontSize": 16,
  "theme": "obsidian",
  "translucency": false
}
```

---

## Files Created by `init-vault`

The `init-vault` action writes the following:

| File | Source |
|------|--------|
| `.obsidian/app.json` | Generated from inline config |
| `.obsidian/core-plugins.json` | Generated from inline config |
| `.obsidian/appearance.json` | Generated from inline config |
| `_templates/*.md` | Copied from `templates/` directory in skill |
| `_MOCs/Home.md` | Minimal vault home with dataview query blocks |
| `_MOCs/Code-Index.md` | Empty codebase index |
| `_MOCs/Paper-Reading-List.md` | Empty paper list |
| `_MOCs/Tag-Index.md` | Empty tag index |
| `0-Inbox/fleeting/.gitkeep` | Placeholder |
| `0-Inbox/daily/.gitkeep` | Placeholder |
| `_attachments/.gitkeep` | Placeholder |

Directories `1-Projects/`, `2-Areas/`, `3-Resources/`, `4-Archives/` are created empty. User adds their projects and areas over time.

---

## Obsidian Conventions Enforced by This Skill

### Wikilinks

```
# CORRECT (Obsidian native):
[[Block-Rotation]]
[[MXFP4-Format|MXFP4 格式]]   # With display alias
[[../2-Areas/Quantization/MXFP4-Format]]  # Relative path

# WRONG (don't use):
[Block-Rotation](Block-Rotation.md)
[Block-Rotation](./Block-Rotation.md)
```

### Frontmatter

```yaml
---
tags: [type/concept, area/quantization, technique/mxfp4, status/draft]
created: 2026-06-01
source: chat_export_20260519.md
---
```

Every `.md` file MUST have `tags:` and `created:` at minimum. Additional fields (arxiv, authors, source, repo_path, etc.) depend on note type.

### MOC (_index.md) Files

Every `1-Projects/<Project>/` and `2-Areas/<Area>/` must have a `_index.md` file. New notes created in those directories are automatically added to the MOC.

### Tags

See `references/merge-workflow.md` (Section: Tag System) for the full taxonomy.

---

## Migrating an Existing Folder into an Obsidian Vault

If the user already has a directory of `.md` files (not yet an Obsidian vault):

1. `init-vault` creates the `.obsidian/` config in that directory
2. The skill re-classifies existing `.md` files into the PARA structure
3. `[[wikilinks]]` are added/updated
4. `_index.md` MOC files are generated based on directory contents

Use `batch re-index` after migrating to regenerate all MOCs.
