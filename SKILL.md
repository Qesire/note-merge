---
name: note-merge
description: |
  Organize raw notes into an Obsidian vault, deepen concept notes through source tracing,
  and diagnose vault health — all driven by a local config file (note-merge.json).
  Five user intents: ingest scattered notes, deepen stub concepts, check vault health, archive completed notes, initialize vault.
  Internal logic uses three independent checks: structure (how to extract from a file),
  reasoning-context (what thinking process to preserve), and reference (whether the note
  has traceable external sources for deepening).
  Trigger on: 整理笔记, 清洗笔记, 合并笔记, 导入笔记, 深化笔记, 深挖, 检查vault,
  clean notes, merge notes, import notes, deepen notes, vault health, check vault,
  聊天记录, chat export, scratch notes, fleeting notes, 初始化vault, init vault,
  随笔, 手记, 研究报告, 论文笔记, 归档笔记, archive notes, 笔记管理, Obsidian, 知识库.
  Do NOT trigger on: creating notes from scratch without source material,
  editing existing polished notes, general file operations.
license: MIT
compatibility: opencode
# The following are Claude Code fields; silently ignored by OpenCode:
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Task", "question"]
argument-hint: "ingest <files> | deepen <concept> | check | archive <note>"
---

# note-merge

Organize raw notes into an Obsidian PARA+Zettelkasten vault. Five actions:

| Intent | Command | One-line | Load |
|--------|---------|----------|------|
| **整理** | `ingest <files>` | Extract knowledge units from source files, classify into vault | `references/merge-workflow.md` |
| **深入** | `deepen <concept>` | Expand a stub/draft into 5-layer analysis (deepen --all-stubs for batch) | `references/concept-deepening.md` |
| **检查** | `check [path]` | Scan vault for broken links, stale notes, config issues (scoped: check 2-Areas/X/) | `references/vault-check.md` |
| **归档** | `archive <note>` | Move a completed note/project into 4-Archives/ | `references/vault-check.md` §Archive |
| **初始化** | `init-vault` | Create vault skeleton + config | `references/vault-setup.md` |

All behavior is driven by `<vault>/note-merge.json`. If absent, prompt `init-vault`.

---

## 0. CONFIGURATION

Read `note-merge.json` before every action. Created during `init-vault`.

```json
{
  "vault": "~/KnowledgeBase",
  "domains": ["<domain-1>", "<domain-2>"],
  "source_repos": ["~/<repo-1>"],
  "language": "zh-CN"
}
```

| Field | Purpose |
|-------|---------|
| `vault` | Path to the Obsidian vault |
| `domains` | Research areas → `2-Areas/<Name>/` directories + classification keywords. Directory name: Title Case each word, preserve hyphens, Chinese as-is |
| `source_repos` | Directories searched during `deepen` for source code tracing |
| `language` | `zh-CN` / `en` / `mixed` — controls filename and heading language |

Full schema: `references/config.schema.md`.

---

## 1–4. DETAILED WORKFLOWS

Each action's full specification lives in its reference file (see table above). SKILL.md only provides the dispatch. Key invariants are listed below as Hard Rules.

---

## 5. HARD RULES

| # | Rule |
|---|------|
| 1 | Never edit, delete, move, replace, or overwrite original source files |
| 2 | Ingest must preserve a raw source snapshot or stable in-vault source link before extraction |
| 3 | Never discard reasoning context: questions, constraints, uncertainty, failed attempts, trade-offs, corrections, and decision rationale must be preserved |
| 4 | Never fabricate content — an accurate stub is better than a hallucinated note |
| 5 | Always read `note-merge.json` before acting |
| 6 | Notes without traceable references (paper, code, experiment) CANNOT be deepened — ask user to provide sources |
| 7 | Classify by matching vault content first, keywords second |
| 8 | Ask user when ambiguous — do not guess |
| 9 | Every .md must have frontmatter with `tags:`, `created:`, `modified:`, `source:`, and `source_snapshot:` when created from ingest. Deepened notes must also have `deepened:` |
| 10 | Internal links → `[[wikilinks]]`, never `[text](path.md)` |
| 11 | Chinese content → Chinese filename; English → kebab-case |
| 12 | Every ingest run generates an `ingest-log-YYYY-MM-DD.md` in `_MOCs/` listing all created/updated/skipped files |

---

## 6. REFERENCE FILES

| Action | Load |
|--------|------|
| `ingest` | `references/merge-workflow.md` |
| `deepen` | `references/concept-deepening.md` |
| `check` / `archive` | `references/vault-check.md` |
| `init-vault` | `references/vault-setup.md` |
| Unexpected input | `references/edge-cases.md` |
| Config validation | `references/config.schema.md` |
