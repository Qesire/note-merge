# Merge Workflow

Full ingest workflow for processing raw source files into the Obsidian vault.

---

## Phase 0: READ CONFIG

Before any processing, read `~/KnowledgeBase/note-merge.json`. If absent, abort and prompt `init-vault`.

Extract `domains[]` — this drives the classification keyword table and AREA directories.

---

## Phase 1: PRESERVE RAW SOURCE

Before reading for extraction, make the ingest non-destructive.

```
1. Never edit, delete, move, replace, or overwrite the user's original source file.
2. If the source file is outside the vault:
   - Create <vault>/3-Resources/Sources/YYYY-MM-DD/ if needed.
   - Copy the source file there using a collision-safe name.
   - If a same-name snapshot exists, append a numeric suffix; do not overwrite it.
3. If the source file is already inside the vault:
   - Do not move it.
   - Treat its current path as source_snapshot.
4. Record source_snapshot for every extracted note.
```

The extracted note is a derivative working note, not a replacement for the source. The raw source remains the ground truth.

---

## Phase 2: INVENTORY — Structure & Reference Check

Read each source file. Run two independent checks. They answer different questions and both must be performed.

### 1.1 Structure check — how to extract

Detect which organizational patterns are present in the file. A file can match zero, one, or multiple patterns.

| Pattern | Signal | Extraction strategy |
|---------|--------|-------------------|
| **Q&A** | `**User**:` / `**Assistant**:` markers, timestamps, conversational turn-taking | Identify Q&A boundaries → group adjacent pairs by topic → preserve questions, constraints, uncertainty, failed attempts, decision rationale, and answer content together |
| **Sections** | `## ` H2 headings, especially structured ones like `方法`, `结果`, `实验`, `Method`, `Results`, `Experiment` | Split at H2 boundaries. Each H2 section → one candidate unit. Merge adjacent short (<50 word) sections on the same topic |
| **Experiment data** | Tables with numeric metrics (MSE, FID, PSNR, accuracy, etc.), config blocks (YAML/JSON), "baseline vs ours" comparison | Keep as experiment record. Config + results table stay together as one unit |
| **Code blocks** | Fenced code blocks (```) | Keep inline if illustrating a concept. Extract standalone to `3-Resources/Code-Tools/` only if it's a reusable tool/script with no surrounding conceptual explanation |
| **None detected** | Free-form prose, no Q&A markers, no H2 headings, no tables | Group by paragraph clusters. Do NOT force-split and do NOT flatten the author's thinking path. Each unit is a stub/draft |

Apply all matched strategies. If strategies produce overlapping units (e.g., a Q&A pair that also contains an experiment table), merge the overlap in the derivative notes only. Never remove content from the raw source snapshot.

### 2.1 Reasoning-context check — what must be preserved

During extraction, explicitly scan for thinking-process signals and preserve them in the derived note:

| Signal | Preserve as |
|--------|-------------|
| User questions, prompts, why this was asked | `## 原始问题` |
| Constraints, assumptions, preferences, scope limits | `## 约束与上下文` |
| Hypotheses, uncertainty, open questions, TODOs | `## 未确定点` |
| Failed attempts, negative results, rejected approaches | `## 失败尝试` |
| Step-by-step reasoning, trade-offs, decision rationale | `## 推理脉络` |
| Corrections, reversals, contradictory claims | `## 待确认` |

Do not classify these as filler. If unsure whether a passage is filler or reasoning context, keep it.

### 1.2 Reference check — what is traceable

Check whether the source file contains references to external, findable material. This affects:
- Whether to offer pulling additional sources during ingest
- Whether the resulting notes can later be deepened

| Signal | Examples | Ingest action |
|--------|----------|--------------|
| **arxiv / DOI / URL** | `arXiv:2405.xxxxx`, `https://doi.org/...`, `paper.pdf` | "这篇笔记引用了 [citation]。需要我拉取原文/元数据吗？" If yes → fetch; if no → record citation in `## 来源` |
| **repo / file path** | `~/TinyFusion/mxfp4.py`, `quant_layer.py:128` | "引用了 [path]。需要我读取代码吗？" If yes → read and incorporate |
| **experiment reference** | `tiny_learned_mxfp4_experiment.py`, `run_ablation.sh`, `results.json` | "提到了实验 [name]。需要我查找实验脚本和输出吗？" If yes → search and attach |
| **none** | No arxiv, path, URL, file name, experiment name | Skip reference pull. Resulting notes will be deepen-blocked until user provides references later |

The structure and reference checks are independent. A file can be:
- Structured Q&A **with** arxiv refs → extract by Q&A, offer to pull paper
- Structured Q&A **without** refs → extract by Q&A, no pull, deepen-blocked
- Free-form **with** a repo path → extract as paragraphs, offer to read code
- Free-form **without** refs → extract as paragraphs, no pull, deepen-blocked

---

## Phase 3: EXTRACT — Strategy by Structure

Apply the extraction strategies identified in the structure check. Each matched pattern produces units:

### Q&A extraction

```
1. Identify Q&A boundaries (timestamps, user prefix changes)
2. Group adjacent Q&A pairs by topic:
   - Same concept discussed across multiple exchanges → one unit
   - Topic shifts to a new concept → new unit
3. For each topic group:
   - Preserve the user's question if it frames motivation, constraints, uncertainty, or decision context
   - Preserve answer/explanation content as the knowledge payload
   - Keep code blocks, technical claims, paper references, corrections, and failed attempts
   - Strip only pure greetings or transport noise that has no research meaning
4. Yield: 2-5 units per file, each tagged with source=<original file name> and source_snapshot=<raw snapshot path>
```

### Section extraction

```
1. Parse H2 headings as section boundaries
2. Each section → one candidate unit (heading becomes the unit's title)
3. Merge adjacent sections if:
   - Both <50 words and on the same topic
   - One section is clearly a sub-detail of the other
4. Skip boilerplate sections only if they contain no citations, assumptions, caveats, or reasoning context. Keep references/caveats that affect interpretation
5. Yield: 1-8 units per file
```

### Experiment data extraction

```
1. Identify config + results as one coherent unit
2. Extract the experiment configuration (model, precision, hyperparams)
3. Extract the results table with numeric metrics
4. Keep them together — do NOT split config from results
5. Add a placeholder ## 分析 section for user to fill
6. Yield: 1 unit per distinct experiment
```

### Free-form extraction

```
1. Scan for coherent idea groups (paragraph clusters on the same topic)
2. Split at clear topic transitions (new concept introduced, subject changes)
3. Preserve the original order of ideas inside each unit when that order reflects thinking or exploration
4. Each unit is thin by nature — do NOT pad
5. DO NOT expand, DO NOT infer missing content
6. Yield: 1-N units, all draft/stub
```

### Quality rules (all extraction types)

- One concept/topic per unit
- Unit must be independently understandable (passes "standalone .md" test)
- If a unit is <50 words and not a code block → consider merging with adjacent related unit
- If extraction yields 0 units → report and skip. Do NOT fabricate
- Preserve reasoning context even if it makes a note less polished
- Do not remove contradictions; mark them under `## 待确认`

---

## Phase 4: CLASSIFY — Match-First

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

## Phase 5: DE-DUPLICATE

```
For each unit at its target location:

1. Check if a file with the same name exists at the target path
2. If yes → present both to user:
    "目标位置已存在 [existing-note]。新笔记: [N] 字, 旧笔记: [M] 字。
     追加 / 创建版本副本 / 跳过？"
3. If no → create new note
4. If similar topic but different name → check first 100 chars of both,
    ask user if they should be merged
```

Never offer destructive replace. If user asks to merge, append with provenance markers and preserve both versions' reasoning context. Use headings like `## 新增自 <source_snapshot>` instead of overwriting existing sections.

---

## Phase 6: FORMAT

Apply standard Obsidian formatting:

```
1. YAML frontmatter:
    - tags: derived from classification + content
    - created: current date
    - source: original file name
   - source_snapshot: vault-relative path to raw source snapshot
2. [[wikilinks]] for all internal references
3. H1 title, H2 sections
4. Single blank line between sections
5. ## 来源 section linking back to source file and source_snapshot
6. Add context sections when present: ## 原始问题 / ## 约束与上下文 / ## 推理脉络 / ## 未确定点 / ## 失败尝试 / ## 待确认
```

### Tag assignment

| Note content | Tags to add |
|-------------|-------------|
| Paper discussion | `#type/paper` |
| Concept explanation | `#type/concept` |
| Experiment data | `#type/experiment` |
| Daily reflection | `#type/daily` |
| Belongs to domain X | `#area/<kebab-X>` |
| Discusses specific technique | `#technique/<name>` (detect from content keywords) |
| Default status | `#status/draft` |

---

## Phase 7: PLACE

```
1. Write .md to target directory using a collision-safe path
2. If target directory doesn't exist → create it (including parent paths)
3. Update parent _index.md MOC:
   - For 1-Projects/<Project>/ and 2-Areas/<Area>/: add [[link]] to the new note
   - Group links under appropriate H2 headings (概念笔记, 实验记录, etc.)
4. If [[wikilinks]] in the note point to non-existent targets:
   - For concrete concepts from paper/code → create a stub
   - For vague references → remove the link, add a ## 待办 bullet
```

If the target .md already exists, do not overwrite it. Use the Phase 5 de-duplication decision: append, create a versioned copy, or skip.

---

## Phase 8: REPORT

```
Output:
  源文件: [N] 个
  原始快照: [N] 个 (列出路径)
  检测到的结构模式: Q&A [n] / 章节 [n] / 实验数据 [n] / 自由文本 [n]
  保留的推理脉络: 原始问题 [n] / 约束 [n] / 未确定点 [n] / 失败尝试 [n] / 待确认 [n]
  检测到的参考: arxiv/DOI [n] / repo路径 [n] / 实验名 [n] / 无 [n]
  创建笔记: [N] 篇
  合并到已有笔记: [N] 篇
  跳过: [N] 篇 (原因: ...)
  更新 MOC: [N] 个
  已拉取补充参考: [N] 项 (列出)
  需要用户手动补充参考: [N] 篇 (列出)
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
│   ├── Sources/YYYY-MM-DD/      Raw source snapshots from ingest
│   └── Tutorials/
└── 4-Archives/
```
