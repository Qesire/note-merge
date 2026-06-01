# Edge Cases / 边界情况处理

When the normal workflow encounters insufficient, contradictory, or oversized input, follow these protocols.

---

## 1. Insufficient Source Material（源信息不足）

**Trigger:** Source file has < 50 words of substantive content AND no code/paper/experiment references to trace.

### Protocol

```
1. Create a stub note with #status/stub
2. In the stub, add a ## 缺失信息 section listing exactly what's needed:
   - 需要补充的具体信息项
   - 建议追溯的代码/论文来源
3. Do NOT attempt to deepen this note
4. Report: "创建了 stub: [[NoteName]]，需要 {具体信息} 才能深化"
5. Do NOT add content beyond what the source provides
```

**Example:**
```markdown
---
tags: [type/concept, area/quantization, status/stub]
created: 2026-06-01
source: chat_export_0601.md
---

# Cayley SGD

## 定义

（源文件中仅提到名称，无详细描述）

## 缺失信息

- [ ] Cayley SGD 相对于标准 SGD 的具体公式差异
- [ ] 在量化旋转中的使用方式（源码位置）
- [ ] 与 QR-Orth、Hadamard 旋转的对比实验数据

## 来源
从聊天记录提取: chat_export_0601.md，仅提及名称，内容不足以深化
```

### Rule

> Never invent content to fill gaps. An accurate stub is better than a hallucinated polished note.

---

## 2. Contradictory Sources（源信息冲突）

**Trigger:** Two or more source files describe the same concept with contradictory claims.

### Protocol

```
1. Identify the specific contradiction point
2. Do NOT merge into a single note
3. Create/update the note with a ## 待确认 section:
   - Cite Source A with the claim and its origin
   - Cite Source B with the conflicting claim and its origin
   - Tag with #status/draft (NOT polished)
4. Report to user with the contradiction highlighted
5. Let user resolve, do NOT pick a side
```

**Example conflict annotation:**
```markdown
## 待确认

以下两点存在矛盾，需核实:

| 来源 | 说法 | 出处 |
|------|------|------|
| chat_export_0519 | MXFP4 的 block_size 统一为 32 | 聊天记录 L42 |
| block_rotation_mxfp4.md 论文 | ViDiT-Q 中 block_size=16 用于 attention | 论文 Section 3.2 |

可能解释: block_size 在不同层类型中不同（linear=32, attention=16），需查源码确认。
```

---

## 3. Mixed-Language Files（中英混排）

**Trigger:** Source file mixes Chinese and English in titles, headings, or body.

### Protocol

| Situation | Rule |
|-----------|------|
| Title/heading is Chinese | Filename: Chinese（如 `扩散模型加速.md`） |
| Title/heading is English | Filename: kebab-case（如 `Diffusion-Sampling-Acceleration.md`） |
| Title/heading is mixed | Use the dominant language (>50% of content) to decide |
| Body is mixed | Keep both languages as-is; Obsidian handles Unicode |
| Code blocks | Always keep as-is, never translate |
| Tags | Always English (as per tag taxonomy) |
| `##` 节标题 | Follow the heading language; Chinese headings → Chinese sections, English headings → English sections |

### If unsure

Default: Chinese filename if any Chinese character appears in the title. Reason: the vault's primary language is Chinese (per user's research context).

---

## 4. Oversized Source Files（超大源文件）

**Trigger:** Source file > 1000 lines.

### Protocol

```
1. Do NOT attempt to extract from the entire file at once
2. Split by natural boundaries:
   - ## H2 headings → one section per heading group
   - Code blocks → extract separately
   - References/bibliography → skip (link to paper note instead)
3. Process in batches of max 500 lines per extraction pass
4. Report progress between batches:
   "已处理 500/1200 行，提取 3 个知识单元..."
```

### What NOT to do

- Do NOT truncate — partial extraction is better than arbitrary cutoff
- Do NOT skip the file — even 1000+ lines may contain valuable knowledge
- Do NOT dump the entire file into one note — this defeats the purpose of extraction

---

## 5. Missing Target for Wikilink（wikilink 目标缺失）

**Trigger:** During PLACE phase, a `[[target]]` in the new note doesn't exist.

### Protocol

```
Decision tree:
  ┌─ Is the target a concrete concept mentioned in a paper or code?
  │  YES → Create stub with #status/stub, source pointing to this note
  │
  ├─ Is the target a project-level note (methods/xxx)?
  │  YES → Create stub, tag with #status/stub, link to the project's _index.md
  │
  ├─ Is the target a vague reference (e.g., "further work")?
  │  YES → Remove the wikilink; add a ## 待办 bullet instead
  │
  └─ Is the target likely a typo?
     YES → Fix the typo if obvious, otherwise ask user
```

---

## 6. Classification Deadlock（分类无法确定）

**Trigger:** Phase 3 classification produces 3+ equally plausible targets, or 0 plausible targets.

### Protocol for 3+ targets

```
1. Present the top 3 options to the user with reasoning:
   "这篇笔记可以放入:
    A) 2-Areas/Quantization/ — 因为讨论的是通用量化概念
    B) 1-Projects/PTQ4DiT/methods/ — 因为直接引用 PTQ4DiT 实验
    C) 3-Resources/Papers/quantization/ — 因为主要内容来自一篇论文"
2. Wait for user choice
3. Do NOT choose arbitrarily
```

### Protocol for 0 targets

```
If no classification rule matches:
  1. Place in 0-Inbox/fleeting/
  2. Tag with #status/draft
  3. Report: "无法自动分类，已放入 0-Inbox/fleeting/，请手动归类"
  4. Suggest 1-2 possible categories for user to consider
```

---

## 7. Format-Only Notes（纯格式化请求）

**Trigger:** User asks to `format` a note that already has valid frontmatter and structure.

### Protocol

```
1. Run the format check
2. If no issues found: "此笔记格式已符合标准，无需修改。评分: 95+"
3. Do NOT make cosmetic-only changes (e.g., re-ordering equivalent frontmatter fields)
4. If only minor issues (e.g., missing #technique/ tag): fix silently and report score
5. If quality already ≥ 90: report with "Ready" status and skip
```
