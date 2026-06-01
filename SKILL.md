---
name: note-merge
description: |
  Organize raw notes into an Obsidian vault, deepen concept notes through source tracing,
  and diagnose vault health — all driven by a local config file (note-merge.json).
  Three user intents: ingest scattered notes, deepen stub concepts, check vault health.
  Internal logic branches by source type (chat export / research report / casual note)
  with different reference-gating rules for each.
  Trigger on: 整理笔记, 清洗笔记, 合并笔记, 导入笔记, 深化笔记, 深挖, 检查vault,
  clean notes, merge notes, import notes, deepen notes, vault health, check vault,
  聊天记录, chat export, scratch notes, fleeting notes, 初始化vault, init vault,
  随笔, 手记, 研究报告, 论文笔记.
  Do NOT trigger on: creating notes from scratch without source material,
  editing existing polished notes, general file operations.
argument-hint: "ingest <files> | deepen <concept> | check"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Task", "AskUserQuestion"]
---

# note-merge

Organize raw notes into an Obsidian PARA+Zettelkasten vault. Three things you can ask me to do:

- **整理** `ingest <files>` — take scattered notes and absorb them into the vault
- **深入** `deepen <concept>` — expand a stub concept note into a 5-layer analysis
- **检查** `check` — scan the vault for broken links, missing frontmatter, stale drafts

All behavior is driven by `~/KnowledgeBase/note-merge.json`. If that file does not exist, I will ask you to run `init-vault` first.

---

## 0. CONFIGURATION

`note-merge.json` is the single source of truth. It is created during `init-vault` and read at the start of every action.

```json
{
  "vault": "~/KnowledgeBase",
  "domains": ["quantization", "diffusion", "low-level-vision"],
  "source_repos": [
    "~/TinyFusion",
    "~/DiTQuantValidation"
  ],
  "language": "zh-CN"
}
```

| Field | Purpose |
|-------|---------|
| `vault` | Path to the Obsidian vault |
| `domains` | Research areas. Each becomes a `2-Areas/<Name>/` directory. Used to generate the classification keyword table |
| `source_repos` | Directories searched during `deepen` for source code tracing |
| `language` | `zh-CN` → Chinese filenames preferred; `en` → kebab-case; `mixed` → per-file judgment |

---

## 1. INGEST（整理）

```
ingest <files...>
```

Take one or more source files and absorb their knowledge into the vault.

### 1.1 Source type detection (first step)

Read each source file. Classify it into one of three types _before_ any processing:

| Type | Signals | Info density | Has references? |
|------|---------|-------------|-----------------|
| **chat-export** | Timestamps, `**User**:` / `**Assistant**:` markers, Q&A structure | High — concept-dense, each Q&A usually targets one concept | Self-contained (conversation IS the reference) |
| **research-report** | arxiv ID, repo paths, experiment names, section headings like `## 方法` / `## 结果` | Medium — structured but may need external context | Has citations that CAN be traced |
| **casual-note** | Free-form thoughts, no clear structure, no citations, personal reflections | Low — ideas scattered, concepts vague | No references; must ask user for sources |

### 1.2 Processing fork by type

**chat-export:**

```
1. Extract Q&A pairs → group by topic
2. Strip conversational filler
3. Classify each topic (match-first, see §1.3)
4. Format + write to vault
5. NO additional reference needed — conversation is self-contained
6. Status: draft
```

**research-report:**

```
1. Check for citations in content:
   - arxiv ID present? → "这篇笔记引用了 arXiv:XXXX，需要我拉取原文吗？"
   - repo path present? → "引用了 ~/xxx/repo，需要我读取代码吗？"
   - experiment name present? → "提到了实验 xxx，需要我查找实验输出吗？"
2. If user provides references → proceed with EXTRACT → CLASSIFY → WRITE
3. If user declines / references inaccessible → write as draft, add a
   ## 缺少的参考  section listing what's needed
4. Status: draft (or polished ONLY if a full deepen passes quality gate)
```

**casual-note:**

```
1. Extract ideas as atomic units
2. Write each as a stub/draft note (use tpl-concept.md template)
3. If the note attempts to describe a technical concept → DO NOT deepen
   without user-provided reference. Reply:
   "这篇笔记中的 ['概念名'] 需要补充参考材料才能深化。
    可以提供一个论文链接、源码路径、或实验数据吗？"
4. Exception: if a casual note contains [[wikilinks]] to existing polished notes,
   cross-link them. But still do not mark the note itself as polished.
5. Status: draft (NEVER polished from casual source alone)
```

### 1.3 Classification: match-first

For each extracted knowledge unit, classify into the vault by matching before guessing:

```
Step 1 — EXACT TITLE MATCH
  Search vault for an existing .md with the same title → if found, this unit
  belongs to that note's directory and should be merged/de-duplicated.

Step 2 — CONTEXT MATCH
  Extract all [[wikilinks]], project names, paper references from the unit.
  Search vault for those references.
  If found → place this unit in the same directory / adjacent to the matched note.
  Example: unit mentions [[Block-Rotation]] which lives in 2-Areas/Quantization/
           → this unit also goes to 2-Areas/Quantization/

Step 3 — KEYWORD FALLBACK
  Only when Steps 1-2 yield nothing.
  Use the domain list from note-merge.json to build a keyword→directory mapping.
  Each domain name becomes both a keyword AND a target directory.
  Additional keywords for each PARA slot:

  | Keywords | Target |
  |----------|--------|
  | 论文, paper, arxiv | 3-Resources/Papers/<topic>/ |
  | 实验, 测试, experiment, 结果 | 1-Projects/<project>/experiments/ |
  | 方法, 算法, method, algorithm | 1-Projects/<project>/methods/ |
  | 教程, 学习, tutorial, guide | 3-Resources/Tutorials/ |
  | 代码, 工具, script, tool | 3-Resources/Code-Tools/ |
  | 讲座, PPT, slides, presentation | 3-Resources/Presentations/ |
  | 日记, 反思, 计划, todo | 0-Inbox/daily/ |

Step 4 — AMBIGUITY RESOLUTION
  If multiple candidates remain → ask user: "放在 A 还是 B？"
  If zero candidates → place in 0-Inbox/fleeting/, report: "无法自动分类"
```

### 1.4 De-duplication

After classification, check if a similar note already exists at the target path:

- Exact same title? → Ask user: merge / replace / keep-both
- Similar topic (same concept, different phrasing)? → Show both titles + first 100 chars, ask user
- No match → create new note

No decision matrix needed — just ask the user.

### 1.5 Output format

Every created note must have:

```markdown
---
tags: [type/..., area/..., status/draft]
created: YYYY-MM-DD
source: <original file name>
---
```

Internal links use `[[wikilinks]]`. Chinese filenames for Chinese content; kebab-case for English.

---

## 2. DEEPEN（深入）

```
deepen <concept-note>
```

Expand a stub or draft concept note using the 5-layer framework. Load `references/concept-deepening.md` for full instructions.

### 2.1 Reference threshold

Before beginning, verify the note has sufficient backing:

| Note's current source | Rule |
|----------------------|------|
| Originated from chat-export | ✅ Allowed — conversation content is reference |
| Has frontmatter `source:` pointing to a paper/code | ✅ Allowed |
| Has [[wikilinks]] to polished notes | ✅ Allowed — those notes provide context |
| Originated from casual-note, no citations, no code refs | ❌ Blocked — reply: "这篇笔记缺乏可追溯的参考材料，无法深化。请提供论文链接、源码路径或实验数据。" |
| Has empty `## 来源` and no frontmatter `source:` | ❌ Blocked — same as above |

### 2.2 Source tracing

Search for code in `source_repos` from `note-merge.json`. Read relevant files. Find experiment outputs.

### 2.3 Quality gate

All 5 layers must pass the sufficiency thresholds defined in `references/concept-deepening.md` (Quality Gate). If any layer fails, keep `status/draft` and list what's missing.

---

## 3. CHECK（检查）

```
check
```

Scan the vault. Report all issues. Do not auto-fix unless user says "fix it."

| Check | What to look for |
|-------|-----------------|
| Broken wikilinks | `[[links]]` whose target .md does not exist. Sort by how many notes reference the broken target (high-traffic stubs first) |
| Stub notes | Notes with `#status/stub` — these need `deepen` |
| Orphan notes | Notes with 0 incoming wikilinks |
| Stale drafts | Draft notes with no modification in >30 days |
| Missing frontmatter | Notes without `tags:` or `created:` |
| Inconsistent status | Deepened-format notes still tagged `draft` |
| Config health | `source_repos` paths exist? `domains` directories exist? |

Output as a priority-ordered list. Broken wikilinks affecting many notes come first.

---

## 4. INIT-VAULT

```
init-vault
```

Create a new Obsidian vault. This is an interactive, one-time setup:

```
1. Ask: "Vault path?" [default ~/KnowledgeBase]
2. Ask: "Research domains? (comma-separated)"
   → Stores in note-merge.json as domains[]
   → Creates 2-Areas/<Each>/ directories with _index.md
3. Ask: "Source code repositories? (paths, comma-separated)"
   → Stores in source_repos[] for deepen tracing
4. Ask: "Primary language? [zh-CN / en / mixed]"
5. Create vault directory structure (PARA skeleton)
6. Write .obsidian/ config files
7. Write note-merge.json
8. Copy templates from templates/ into _templates/
```

Load `references/vault-setup.md` for the directory skeleton and Obsidian config details.

---

## 5. HARD RULES

| # | Rule |
|---|------|
| 1 | Never delete original source files |
| 2 | Never fabricate content — an accurate stub is better than a hallucinated note |
| 3 | Always read `note-merge.json` before acting |
| 4 | Casual notes CANNOT be deepened without user-provided references |
| 5 | Classify by matching vault content first, keywords second |
| 6 | Ask user when ambiguous — do not guess |
| 7 | Every .md must have frontmatter with `tags:` and `created:` |
| 8 | Internal links → `[[wikilinks]]`, never `[text](path.md)` |
| 9 | Chinese content → Chinese filename; English → kebab-case |

---

## 6. REFERENCE FILES

| Action | Load |
|--------|------|
| `ingest` | `references/merge-workflow.md` |
| `deepen` | `references/concept-deepening.md` |
| `check` | `references/edge-cases.md` |
| `init-vault` | `references/vault-setup.md` |
| Any action encountering unexpected input | `references/edge-cases.md` |
