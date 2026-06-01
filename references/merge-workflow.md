# Merge Workflow: Phase Details

Full 7-phase workflow for processing raw notes into the KnowledgeBase.

---

## Phase 1: INVENTORY

Read all source files. For each file, determine:
- **Type**: `chat-export`, `paper-note`, `concept-note`, `experiment-log`, `lecture-note`, `daily-journal`, `code-snippet`, `mixed`
- **Primary topic**: quantization, diffusion, low-light, compression, tooling, career, other
- **Quality**: well-structured / needs-cleaning / noisy
- **Size**: single-concept / multi-concept / dump

Report the inventory to the user before proceeding.

---

## Phase 2: EXTRACT

For each source file, extract **atomic knowledge units**. Rules:
- One concept/topic per unit
- Strip conversational filler (greetings, meta-commentary, "let me think...")
- Keep: factual statements, technical insights, code patterns, paper references, experimental results, questions/todos
- Discard: pure chat boilerplate, emoji-only lines, duplicate adjacent lines

For **chat exports**: identify Q&A pairs, extract the answer/content, discard the question if it adds no value.

---

## Phase 3: CLASSIFY

Assign each unit to the correct PARA location. Classification uses three sources of signal, applied in priority order.

### 3.1 Primary: frontmatter / explicit declaration

If the source file has YAML frontmatter or explicit classification markers, use those first:

| Signal | Classification |
|--------|---------------|
| `arxiv:` in frontmatter | `3-Resources/Papers/<topic>/` |
| `project:` in frontmatter | `1-Projects/<Project>/` |
| `status: polished/draft/stub` | Respect the status, place by content |
| `## 论文笔记` heading | `3-Resources/Papers/<topic>/` |
| `## 实验记录` heading | `1-Projects/<Project>/experiments/` |

### 3.2 Secondary: keyword-to-PARA mapping

| Keywords (Chinese) | Keywords (English) | Target directory |
|---------------------|--------------------|-----------------|
| 实验, 测试, 跑, 训练, 脚本, 配置, 结果, 精度, MSE, FID | experiment, test, run, train, script, config, result, accuracy, metric | `1-Projects/<Project>/experiments/` |
| 方法, 算法, 实现, 架构, 管线 | method, algorithm, implementation, architecture, pipeline | `1-Projects/<Project>/methods/` |
| 论文, arxiv, paper, 文献, 阅读, 作者, 发表 | paper, arxiv, reading, author, published, conference | `3-Resources/Papers/<topic>/` |
| 概念, 定义, 什么是, 原理, 为什么, 机制, 原因 | concept, definition, what is, principle, why, mechanism | `2-Areas/<Area>/` |
| 教程, tutorial, 入门, 学习笔记, 课程, 教学 | tutorial, introduction, course, learn, guide | `3-Resources/Tutorials/` |
| 代码, 工具, 脚本, CLI, 命令, github, repo | code, tool, script, CLI, command, github, repo, repo_path | `3-Resources/Code-Tools/` |
| 讲座, PPT, slides, 报告, 汇报, presentation | lecture, PPT, slides, talk, presentation | `3-Resources/Presentations/` |
| 日记, 记录, 今天, 反思, todo, 计划, 想法 | diary, journal, today, reflection, todo, plan, idea | `0-Inbox/daily/` |
| 随手记, 杂, 碎片, 临时, 待分类 | scratch, fleeting, temp, uncategorized, misc | `0-Inbox/fleeting/` |

### 3.3 Tertiary: content structure heuristics

When keywords are ambiguous or missing:

| Heuristic | Classification | Confidence |
|-----------|---------------|------------|
| Content >200 lines | Paper note or tutorial (check for arxiv refs) | Medium |
| Content <20 lines | Fleeting or stub | Medium |
| Contains ``` code blocks AND no experiment results | Code-Tools | Medium |
| Contains markdown tables with numeric metrics (MSE, FID, etc.) | Experiment | High |
| Contains @author or arXiv:XXXX.XXXXX pattern | Paper | High |
| Contains section headings like `## 定义`, `## 为什么重要` | Concept | High |
| Contains timestamps and user/assistant markers | Chat export → trigger clean handler | High |
| File begins with YAML frontmatter (---) | Use its `tags:` field for classification | High |

### 3.4 Classification priority rules

When multiple signals conflict, apply this priority:

```
1. User explicitly specifies target → ALWAYS follow user override
2. Source file frontmatter (tags:, arxiv:, project:) → strongest automatic signal
3. Content structure heuristics (table rows > 3, section headings present) → strong
4. Keyword match count → more matching keywords = higher confidence
5. Content length → long (>200 lines) favors paper/tutorial; short favors concept/stub
6. If still ambiguous → ask user with top 2-3 suggestions
```

### 3.5 Multi-project disambiguation

If a note mentions multiple projects (e.g., "compared TinyFusion and PTQ4DiT"):

```
1. Check which project has the most keyword matches
2. Check which project the source file path is closest to (file paths)
3. If tied → ask user: "This note references both [ProjA] and [ProjB]. Where should it go?"
4. Alternative: place in the Area note (2-Areas/) and link to both projects
```

### 3.6 Unit-to-directory summary table

| Unit type | Target directory |
|-----------|-----------------|
| Paper summary/review | `3-Resources/Papers/<topic>/` |
| Technical concept/definition | `2-Areas/<Area>/` as atomic .md |
| Experiment result/log | `1-Projects/<Project>/experiments/` |
| Method/algorithm analysis | `1-Projects/<Project>/methods/` |
| Lecture/PPT learning notes | `3-Resources/Presentations/` |
| Tutorial/background learning | `3-Resources/Tutorials/` |
| Code snippet/tool note | `3-Resources/Code-Tools/` |
| Personal reflection/todo | `0-Inbox/daily/` or `2-Areas/Career/` |
| Fleeting/uncategorized | `0-Inbox/fleeting/` |

---

## Phase 4: DE-DUPLICATE

For each unit, check if similar content already exists in the vault:
1. Search for exact title match in `~/KnowledgeBase/`
2. Search for semantic overlap (same paper title, same concept name)
3. If match found → use `resolve` action (see `references/conflict-resolution.md`) to present comparison and decision matrix:
   - **Replace**: new note is significantly more complete (longer + more links)
   - **Merge**: complementary content, combine sections
   - **Skip**: existing note is already `polished`
   - **Keep both**: same title but different topic/area → save with `_v2` suffix
4. For batch operations: when user selects APPLY-TO-ALL-SIMILAR, auto-apply the same decision rule to subsequent similar conflicts

---

## Phase 5: FORMAT

Apply standard formatting:
- Add YAML frontmatter with `tags`, `created` date, `source` reference
- Use Obsidian `[[wikilinks]]` for internal references
- Add `# Headers` in proper hierarchy (H1 title, H2 sections)
- Normalize whitespace (single blank line between sections)
- Add `## 来源` section linking back to original file

**Tag assignment:**
- `#type/paper` for paper notes
- `#type/concept` for concept/definition notes
- `#type/experiment` for experiment logs
- `#type/daily` for journal entries
- `#area/quantization`, `#area/diffusion`, etc.
- `#technique/ptq`, `#technique/mxfp4`, etc. based on content
- `#status/draft` as default (user polishes later)

---

## Phase 6: PLACE

Write each unit to its target location:
- Create `.md` file with kebab-case filename (Chinese content: use concise Chinese filename)
- Update relevant `_index.md` MOC files with links to new notes
- If linking to an existing concept note that doesn't exist yet, create a stub with `#status/stub`

**Naming conventions:**
- English concepts: `Block-Rotation.md`, `MXFP4-Format.md`
- Chinese notes: `低光照增强综述.md`, `扩散模型加速采样.md`
- Papers: `FirstAuthor-Year-ShortTitle.md` or use arXiv ID

---

## Phase 7: REPORT

Summarize:
- Files processed: N
- Notes created: N (by PARA category)
- Notes merged: N (with existing note paths)
- Notes skipped: N (reason)
- MOC files updated: N
- Stub notes created: N

---

## Special Handlers

### Chat Export Handler

For files like `chat_export_*.md`:
- Identify Q&A boundaries (look for timestamp/user prefixes)
- Extract only the assistant/answer content
- Group by topic, then apply Phase 2-6 per topic
- Common patterns: `**User**: ...`, `> ...`, `## ...`

### Multi-Concept Long File Handler

For files >200 lines with mixed content:
- Split into sections by `## Header` or topic boundaries
- Process each section as a separate unit
- Original file can be archived to `4-Archives/`

### Code Snippet Handler

For notes containing code blocks:
- Extract standalone code to `3-Resources/Code-Tools/`
- Add `## 运行方式` section
- Link back to the project it belongs to

---

## KnowledgeBase Structure Reference

```
~/KnowledgeBase/
├── _MOCs/           # Global indexes (Home, Code-Index, Paper-Reading-List, Tag-Index)
├── _templates/      # Note templates (tpl-project-index, tpl-codebase, tpl-paper-note, etc.)
├── _attachments/    # Images, PDFs
├── 0-Inbox/         # fleeting/ + daily/
├── 1-Projects/      # 6 active projects (DartQuant-Diffusion, PTQ4DiT, TinyFusion, Wan-Quantization, LLIEDiff, DiTQuant-Validation) + each has methods/ experiments/ _index.md Codebase.md
├── 2-Areas/         # Quantization, Diffusion-Models, Low-Level-Vision, Model-Compression, Career
├── 3-Resources/     # Papers/(quantization,diffusion,low-light,model-compression,others), Code-Tools, Presentations, Tutorials
└── 4-Archives/      # AdamOptimizer-Demo, DuQuant-v2
```

## Tag System

| Category | Tags |
|----------|------|
| Note type | `#type/paper` `#type/concept` `#type/experiment` `#type/moc` `#type/daily` `#type/codebase` |
| Area | `#area/quantization` `#area/diffusion` `#area/vision` `#area/systems` |
| Technique | `#technique/ptq` `#technique/qat` `#technique/mxfp4` `#technique/pruning` `#technique/block-rotation` |
| Status | `#status/active` `#status/draft` `#status/polished` `#status/toread` `#status/archived` `#status/stub` |
| Other | `#repo` |

## Template Alignment

- `tpl-concept.md` uses `## 定义` / `## 为什么重要` — use this for **initial/draft** concept notes (status/draft)
- Deepened concept notes use `## 1. 动机` / `## 2. 机制` / ... `## 5. 系统性` — use this for **polished** concept notes (status/polished)
- The `deepen` action transforms draft template format → 5-layer polished format

## Examples

### Example 1: Chat export → concept note

**Input: Chat export about MXFP4**
```
**User**: what is mxfp4?
**Assistant**: MXFP4 is a 4-bit floating point format with E2M1 mantissa and E8M0 shared block scale...
```

**Output: `2-Areas/Quantization/MXFP4-Format.md`**
```markdown
---
tags: [type/concept, area/quantization, technique/mxfp4, status/draft]
created: 2026-06-01
source: chat_export_20260519_233042.md
---

# MXFP4 格式

## 定义
MXFP4 是 4-bit 浮点格式，采用 E2M1 mantissa + E8M0 共享 block scale...

## 关联概念
- [[Block-Rotation]]
- [[PTQ-vs-QAT]]

## 来源
从聊天记录提取: chat_export_20260519_233042.md
```

### Example 2: Paper note import

**Input: arXiv paper PDF notes**
```
Paper: PTQ4DiT — Post-Training Quantization for Diffusion Transformers
Key idea: block-wise reconstruction with timestep shuffling
Result: W4A4 achieves <0.5 FID degradation on ImageNet 256
```

**Output: `3-Resources/Papers/quantization/ptq4dit.md`**
```markdown
---
tags: [type/paper, area/quantization, technique/ptq, status/toread]
arxiv: 2405.xxxxx
authors: ...
year: 2024
topic: quantization
---

# PTQ4DiT

## 一句话总结
Block-wise reconstruction for DiT PTQ with timestep-aware calibration.

## 核心方法
- Timestep shuffling in calibration
- Block-level reconstruction with MSE loss
- ...

## 与我的研究关联
- 关联项目: [[../../1-Projects/PTQ4DiT/_index|PTQ4DiT]]
- 关联概念: [[Block-Reconstruction]], [[Timestep-Dependent-Activations]]
```

### Example 3: Experiment log import

**Input: Experiment log**
```
Experiment: tiny_learned_mxfp4_experiment.py
Config: w4a4, block_size=32, TinyDiT model
Results: learned_block_w4a4 MSE=0.0023 vs baseline RTN MSE=0.0081
```

**Output: `1-Projects/DiTQuant-Validation/experiments/tiny-learned-mxfp4-results.md`**
```markdown
---
tags: [type/experiment, area/quantization, technique/mxfp4, technique/block-rotation, status/draft]
created: 2026-06-01
source: ~/DiTQuantValidation/src/dit_quant_validation/tiny_learned_mxfp4_experiment.py
---

# Tiny Learned MXFP4 Experiment

## 配置
- Model: TinyDiT
- Precision: w4a4
- Block size: 32

## 结果
| Method | MSE |
|--------|-----|
| RTN (baseline) | 0.0081 |
| Block Hadamard | 0.0042 |
| Learned Block | 0.0023 |

## 关联概念
- [[MXFP4-Format]]
- [[Block-Rotation]]
- [[../../../2-Areas/Quantization/Adaptive-Rounding|Adaptive Rounding]]
```
