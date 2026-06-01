# Merge Workflow

Full ingest workflow for processing raw source files into the Obsidian vault.

---

## Phase 0: READ CONFIG

Before any processing, read `~/KnowledgeBase/note-merge.json`. If absent, abort and prompt `init-vault`.

Extract `domains[]` — this drives the classification keyword table and AREA directories.

---

## Phase 1: INVENTORY — Source Type Detection

Read each source file. Determine its type. The type determines everything downstream.

### Detection Signals

| Signal | → Type |
|--------|--------|
| Contains `**User**:`, `**Assistant**:`, timestamps, Q&A markers | **chat-export** |
| Contains arxiv ID (`arXiv:\d{4}\.\d+`), repo paths (`~/...`), experiment names, structured sections (`## 方法`, `## 结果`, `## Experiment`) | **research-report** |
| None of the above; free-form text, personal reflections, scattered ideas | **casual-note** |

### Ambiguous cases

If a file has weak signals of two types:
- Has some Q&A markers but no timestamps, AND mentions arxiv → treat as research-report (higher standard)
- Has structured headings but no citations → treat as casual-note (no reference = casual)
- Chat export that contains research discussion with arxiv refs → treat as chat-export (self-contained still applies)

---

## Phase 2: EXTRACT — Branch by Type

### chat-export

```
1. Identify Q&A boundaries (timestamps, user prefix changes)
2. Group adjacent Q&A pairs by topic
3. For each topic group:
   - Extract the answer content as the knowledge payload
   - Discard questions (unless the question itself contains substantive framing)
   - Keep code blocks, paper references, technical claims
   - Strip: greetings, "let me think...", meta-commentary
4. Yield: 2-5 atomic knowledge units, each tagged with source="chat-export"
```

### research-report

```
1. Check what citations are present:
   - arxiv ID? → note it; offer to fetch paper metadata
   - repo path? → note it; offer to read code
   - experiment name? → note it; offer to find output
2. If user provides additional reference material → incorporate it
3. Extract structured knowledge:
   - Each ## section that describes a distinct method/concept → one unit
   - Experiment results (tables, metrics) → one unit
   - Code snippets describing implementation → inline or separate Code-Tools unit
4. Yield: 1-6 units, each tagged with the reference it depends on
```

### casual-note

```
1. Scan for coherent idea groups (paragraphs that form a single thought)
2. Extract each as a unit — even if thin
3. If a unit mentions a concept by name → create the unit as a stub
4. DO NOT expand, DO NOT infer missing content, DO NOT deepen
5. Each unit's frontmatter should include source: pointing to the original note
6. Yield: 1-N units, all thin, all status=draft (never polished)
```

### Extraction quality rules (all types)

- One concept/topic per unit
- Unit must be independently understandable (passes "standalone .md" test)
- If a unit is <50 words and not a code block → consider merging with adjacent related unit
- If extraction yields 0 units → report and skip. Do NOT fabricate.

---

## Phase 3: CLASSIFY — Match-First

Classification proceeds in four steps. Stop at the first step that produces a clear result.

### Step 1: Exact Title Match

```
1. Take the unit's title or H1 heading
2. Search ~/KnowledgeBase/ for an existing .md with the same basename
3. If found → unit belongs to the same directory as that note
   → Skip to Phase 4 (de-duplicate against the existing note)
```

### Step 2: Context Match

```
1. Extract all [[wikilinks]], project names, paper references from the unit content
2. For each reference:
   - Search vault for a .md matching that reference name
   - If found → note the directory it lives in
3. If ALL references point to the same directory → unit goes there
4. If references point to multiple directories → use the most specific one
   (project > area > resource)
5. If at least one reference matches → classification complete
```

### Step 3: Keyword Fallback

Build the keyword mapping table from `note-merge.json` domains:

```
For each domain in note-merge.json:
  Keyword: domain name, Chinese equivalent, common abbreviations
  Target:  2-Areas/<DomainName>/

Generic keywords (always active):

| Keywords | Target |
|----------|--------|
| 论文, paper, arxiv | 3-Resources/Papers/<topic>/ |
| 实验, 测试, experiment, 结果, 精度, metric | 1-Projects/<project>/experiments/ |
| 方法, 算法, method, algorithm, 实现, 架构 | 1-Projects/<project>/methods/ |
| 概念, 定义, 什么是, concept, definition | 2-Areas/<best-match-domain>/ |
| 教程, tutorial, 入门, guide, 学习 | 3-Resources/Tutorials/ |
| 代码, 工具, script, tool, CLI | 3-Resources/Code-Tools/ |
| 讲座, PPT, slides, presentation, 报告 | 3-Resources/Presentations/ |
| 日记, 反思, 计划, todo, 今天, daily | 0-Inbox/daily/ |

Match by counting keyword occurrences in the unit's title + first 200 chars.
The category with the most matches wins.
```

For `<project>` and `<topic>` in the paths above: if the unit content names a specific project (matching a directory under `1-Projects/`) or paper topic (matching a directory under `3-Resources/Papers/`), use that. Otherwise use the best domain match or leave as a generic slot.

### Step 4: Ambiguity Resolution

```
- Multiple candidates with equal match scores → ask user to choose
- Zero keyword matches → place in 0-Inbox/fleeting/
  → Report: "无法自动分类 [unit-title]，已放入 0-Inbox/fleeting/"
```

---

## Phase 4: DE-DUPLICATE

```
For each unit at its target location:

1. Check if a file with the same name exists at the target path
2. If yes → present both to user:
   "目标位置已存在 [existing-note]。新笔记: [N] 字, 旧笔记: [M] 字。
    合并 / 替换 / 保留两份 / 跳过？"
3. If no → create new note
4. If similar topic but different name → check first 100 chars of both,
   ask user if they should be merged
```

No pre-computed decision matrix. Ask the user. They know better than any heuristic.

---

## Phase 5: FORMAT

Apply standard Obsidian formatting:

```
1. YAML frontmatter:
   - tags: derived from classification + content
   - created: current date
   - source: original file name
2. [[wikilinks]] for all internal references
3. H1 title, H2 sections
4. Single blank line between sections
5. ## 来源 section linking back to source file
```

### Tag assignment

| Note content | Tags to add |
|-------------|-------------|
| Paper discussion | `#type/paper` |
| Concept explanation | `#type/concept` |
| Experiment data | `#type/experiment` |
| Daily reflection | `#type/daily` |
| From chat-export | `#status/draft` |
| From research-report | `#status/draft` (or polished only if deepen passed) |
| From casual-note | `#status/draft` |
| Belongs to domain X | `#area/<kebab-X>` |
| Discusses specific technique | `#technique/<name>` (detect from content keywords) |

---

## Phase 6: PLACE

```
1. Write .md to target directory
2. If target directory doesn't exist → create it (including parent paths)
3. Update parent _index.md MOC:
   - For 1-Projects/<Project>/ and 2-Areas/<Area>/: add [[link]] to the new note
   - Group links under appropriate H2 headings (概念笔记, 实验记录, etc.)
4. If [[wikilinks]] in the note point to non-existent targets:
   - For concrete concepts from paper/code → create a stub
   - For vague references → remove the link, add a ## 待办 bullet
```

---

## Phase 7: REPORT

```
Output:
  源文件: [N] 个
  识别类型: chat-export [n] / research-report [n] / casual-note [n]
  创建笔记: [N] 篇
  合并到已有笔记: [N] 篇
  跳过: [N] 篇 (原因: ...)
  更新 MOC: [N] 个
  需要用户补充参考: [N] 篇 (列出)
```

---

## Templates

When creating notes, use these templates (from `templates/`):

- **Concept (draft/stub):** `tpl-concept.md` — `## 定义` / `## 为什么重要`
- **Concept (deepened/polished):** `tpl-concept-deepened.md` — 5-layer structure
- **Paper note:** `tpl-paper-note.md` — arxiv, authors, one-sentence summary, method, results
- **Experiment log:** `tpl-experiment.md` — config, results table, analysis

---

## Tag System

| Category | Tags |
|----------|------|
| Note type | `#type/paper` `#type/concept` `#type/experiment` `#type/moc` `#type/daily` |
| Status | `#status/draft` `#status/stub` `#status/polished` `#status/toread` `#status/archived` |
| Area | Generated from `domains[]`: `#area/quantization` `#area/diffusion` etc. |
| Technique | Detected from content: `#technique/ptq` `#technique/mxfp4` `#technique/hadamard` etc. |

---

## KnowledgeBase Structure

```
~/KnowledgeBase/                (value of note-merge.json vault)
├── .obsidian/                  Obsidian config
├── _templates/                 Note templates
├── _MOCs/                      Global indexes
├── _attachments/               Images, PDFs
├── 0-Inbox/
│   ├── fleeting/               Uncategorized
│   └── daily/                  Daily journals
├── 1-Projects/
│   └── <Project>/              _index.md, Codebase.md, methods/, experiments/
├── 2-Areas/
│   └── <Domain>/               (from domains[] in config) _index.md + concept .md files
├── 3-Resources/
│   ├── Papers/<topic>/
│   ├── Code-Tools/
│   ├── Presentations/
│   └── Tutorials/
└── 4-Archives/
```
