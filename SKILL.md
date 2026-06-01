---
name: note-merge
description: |
  Clean, classify, merge, and deepen notes in the PARA+Zettelkasten knowledge base.
  Use this skill when the user has random notes (chat exports, scratch files, scattered .md files,
  fleeting thoughts, meeting notes, paper drafts) that need to be cleaned up and absorbed into
  the structured KnowledgeBase vault (~/KnowledgeBase/).
  Also use this skill when the user asks to deepen or enrich existing concept notes —
  tracing each concept through source code to answer "why" questions at every layer.
  Covers: deduplication, formatting cleanup, concept extraction, PARA classification,
  frontmatter tagging, cross-linking to existing notes, file placement,
  and 5-layer concept deepening (motivation → mechanism → design rationale → evidence → system coupling).
  Trigger on: 整理笔记, 清洗笔记, 合并笔记, 导入笔记, 深化笔记, 深挖, clean notes, merge notes,
  import notes, deepen notes, 随笔, 零散笔记, 聊天记录, chat export, scratch notes, fleeting notes.
  Do NOT trigger on: creating new notes from scratch, editing existing notes in the vault,
  or general note-taking — use standard file editing tools for those.
argument-hint: "[action] [target] — actions: merge, clean, import, deepen, audit, link-check, format, classify"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob", "Task", "AskUserQuestion"]
---

# Note Merge Skill

Clean, classify, merge, and deepen notes in the PARA+Zettelkasten knowledge base at `~/KnowledgeBase/`.

---

## 1. ACTIONS

Parse the user's request to determine which action to run. If ambiguous, ask.

### 1.1 `merge <files>` — Full multi-file import

Process one or more raw source files through the full 7-phase pipeline:

```
INVENTORY → EXTRACT → CLASSIFY → DE-DUPLICATE → FORMAT → PLACE → REPORT
```

**Use when:** user provides multiple raw files, chat exports, or scattered notes to clean up.
**Load:** `references/merge-workflow.md` for detailed phase instructions.

### 1.2 `import <file>` — Single file quick import

Lightweight import for a single well-structured file. Skip inventory phase, go directly to classify → format → place.

**Use when:** user provides a single paper note, experiment log, or tutorial that doesn't need extraction.
**Load:** `references/merge-workflow.md` (Phase 3-7 only).

### 1.3 `clean <chat-export>` — Chat export cleaning

Extract only the substantive knowledge from chat exports. Strip conversational filler, group by topic, format each topic as a draft concept note.

**Use when:** user provides chat exports (`chat_export_*.md`) or any conversation dump.
**Load:** `references/merge-workflow.md` (Special Handlers: Chat Export Handler).

### 1.4 `deepen <concept>` — 5-layer concept deepening

Transform a draft/stub concept note into a polished 5-layer note. Trace into source code, find experiment data, add cross-references.

**Use when:** user says 深化, 深挖, deepen, or asks "why" questions about a concept.
**Load:** `references/concept-deepening.md` for the full 5-layer framework and quality gates.

### 1.5 `classify <files>` — Dry-run classification

Read source files and output a classification plan (which units go where) without writing any files. Report the plan for user review.

**Use when:** user wants to preview placement before committing to changes.

### 1.6 `audit` — Vault health scan

Scan `~/KnowledgeBase/` and report:

| Check | What to look for |
|-------|-----------------|
| Broken wikilinks | `[[links]]` whose target .md file does not exist |
| Stub notes | Notes with `#status/stub` — these need `deepen` |
| Orphan notes | Notes with 0 incoming wikilinks from other notes |
| Stale drafts | Draft notes (`#status/draft`) with no modification in >30 days |
| Missing MOC entries | New notes not listed in their parent `_index.md` |
| Missing frontmatter | Notes without `tags:` field |
| Inconsistent status | Deepened-format notes still tagged `status/draft` |

Report a prioritized list of issues. Do not auto-fix unless user approves.

### 1.7 `link-check` — Verify all wikilinks

Parse every `[[link]]` in `~/KnowledgeBase/` and verify the target file exists. Report broken links with source file and line number.

### 1.8 `format <note>` — Apply template to existing note

Add missing frontmatter fields, normalize headings, ensure `## 来源` section exists, update tags. Does not change the content body.

---

## 2. HARD RULES (Non-Negotiable)

These rules apply to all actions. Violation means the output is invalid.

| # | Rule |
|---|------|
| 1 | **Never delete** original source files — only copy/transform. |
| 2 | **Always preview** the classification plan (dry-run) before writing files. |
| 3 | **Ask user** when classification is ambiguous (multiple projects/areas match). |
| 4 | **Preserve original content** meaning — do not hallucinate, embellish, or add unsourced claims. |
| 5 | **Mark merged notes** with `source:` in frontmatter to trace provenance. |
| 6 | **Every .md file must have frontmatter** — at minimum `tags:` and `created:` fields. |
| 7 | **All internal links must be `[[wikilinks]]`** — never use `[text](path.md)` for vault-internal references. |
| 8 | **Chinese content → Chinese filename** (not pinyin or English translation). English content → kebab-case. |
| 9 | **Use `_index.md` MOC files** — every new note in `2-Areas/<Area>/` and `1-Projects/<Project>/` must be listed in the area/project MOC. |
| 10 | **Verify wikilinks before writing** — every `[[target]]` in a new note must have a target that exists, or a stub must be created. |
| 11 | **Default status is `draft`** — never mark a note `polished` unless user explicitly requests or a `deepen` action completes with all quality gates passed. |
| 12 | **Report, don't silently skip** — if a unit is skipped (duplicate, unclear classification), report why in Phase 7. |

---

## 3. QUALITY SCORING

When creating or formatting notes, start at 100 and deduct per issue. Report the score.

| Severity | Issue | Deduction |
|----------|-------|-----------|
| Critical | Missing frontmatter (`tags:` field absent) | -20 |
| Critical | Wrong directory (note placed outside its PARA category) | -20 |
| Critical | Content hallucination (claim not in source) | -20 |
| Major | No `source:` in frontmatter (provenance lost) | -10 |
| Major | No `## 来源` section linking back to original | -10 |
| Major | Missing from parent `_index.md` MOC | -10 |
| Major | Broken wikilink (target does not exist, no stub created) | -10 |
| Major | Wrong filename convention (Chinese content with English filename or vice versa) | -5 |
| Minor | No `created:` date in frontmatter | -3 |
| Minor | Missing `#area/` tag where appropriate | -3 |
| Minor | Unnecessary whitespace (>2 consecutive blank lines) | -2 |
| Minor | Missing `#technique/` tag where a specific technique is discussed | -2 |

**Thresholds:** ≥ 90 Ready | 80-89 Acceptable (fix minor issues) | < 80 Must fix

For `deepen` actions, use the deepening-specific quality gate in `references/concept-deepening.md` (Section: Quality Gate).

---

## 4. SAFETY RULES

- **Never delete** original source files — only copy/transform
- **Always preview** the classification plan before writing
- **Ask user** when classification is ambiguous (multiple projects/areas match)
- **Preserve original content** meaning — do not hallucinate or embellish
- **Mark merged notes** with `source:` in frontmatter to trace provenance

---

## 5. ERROR HANDLING

| Situation | Action |
|-----------|--------|
| Classification ambiguous (multiple projects match) | Ask user to choose, listing the options |
| Target directory doesn't exist | Create it following the KB structure conventions |
| De-duplication finds multiple matches | Present all matches, let user choose merge/replace/skip |
| Wikilink target doesn't exist | Create a stub note with `#status/stub` |
| Source file is empty or contains no extractable units | Report and skip, do not create empty notes |
| Frontmatter parsing fails (malformed YAML) | Report the file path, skip, do not attempt repair |

---

## 6. REFERENCE FILES

Load these as needed based on the action:

| Action | Reference to load |
|--------|------------------|
| `merge`, `import`, `clean`, `classify` | `references/merge-workflow.md` — phases, handlers, KB structure, tag system, examples |
| `deepen` | `references/concept-deepening.md` — 5-layer framework, tracing rules, quality gate |

**Base directory:** `~/.config/opencode/skills/note-merge/`
