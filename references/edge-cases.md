# Edge Cases

Boundary scenarios and their handling protocols. Load this when any action encounters input that doesn't fit the normal flow.

---

## 1. Insufficient Source Material

**Trigger:** Source file has <50 words, no citations, no code references.

```
- Create a stub (NOT a polished note)
- Add ## 缺失信息 section listing what's needed
- Do NOT deepen. Report: "创建 stub，需要 {具体信息}"
- Do NOT invent content
- Preserve the original source snapshot anyway; a thin note must still link back to the raw source
```

---

## 2. Reference Missing for Deepen

**Trigger:** User requests `deepen` on a note that has no traceable reference.

Check the note's current state for reference signals:

| The note has... | Action |
|----------------|--------|
| Frontmatter `source:` pointing to paper (arxiv/DOI/title) or code (repo/file path) | ✅ Allow — the source is traceable |
| References to specific experiment scripts or output logs | ✅ Allow — experiments are traceable evidence |
| `[[wikilinks]]` to existing polished notes | ✅ Allow — those notes provide traceable context |
| `## 来源` section with concrete, findable references | ✅ Allow |
| None of the above | ❌ Block — reply: "这篇笔记缺乏可追溯的参考材料（论文、代码、实验数据）。无法深化。请提供至少一项外部来源。" |

This check is on the note's CURRENT state, not its original source type. A note that was ingested from Q&A chat may have references embedded in its content. A note that was ingested from a "paper note" file may have lost its references in extraction. What matters is what's in the note now. If `source_snapshot:` exists, inspect the raw snapshot before declaring references missing.

---

## 2a. Existing Target Note / Overwrite Risk

**Trigger:** Ingest would write to a path that already exists, or the user asks to merge into an existing note.

```
- Never overwrite the existing note.
- Never replace existing sections destructively.
- Offer only: append / create-versioned-copy / skip.
- If appending, add a provenance heading: ## 新增自 <source_snapshot>
- Preserve both the old note's reasoning context and the new source's reasoning context.
- If the user explicitly says "replace", ask for confirmation and recommend versioned copy instead.
```

---

## 3. Contradictory Sources

**Trigger:** Multiple sources describe the same concept with conflicting claims.

```
- Identify the specific contradiction
- Add a ## 待确认 section with both claims cited
- Tag with #status/draft (NOT polished)
- Report to user, let them resolve
- Do NOT pick a side
```

---

## 4. Mixed-Language Files

| Situation | Rule |
|-----------|------|
| Title is Chinese | Filename: Chinese |
| Title is English | Filename: kebab-case |
| Mixed | Use dominant language (>50% of content) |
| Code blocks | Never translate |
| Tags | Always English |
| Section headings | Match heading language |
| Uncertain | Default Chinese (if `language: zh-CN` in config) |

---

## 5. Oversized Source Files (>1000 lines)

```
- Do NOT process entire file at once
- Split by ## H2 headings
- Process in batches of max 500 lines
- Report progress between batches
- Do NOT truncate or skip
- Do NOT dump entire file into one note
- Preserve a raw source snapshot before batch processing
- Keep cross-batch reasoning links: if a later batch depends on an earlier question/constraint, mention that dependency in `## 约束与上下文`
```

---

## 6. Missing Wikilink Target

**Trigger:** During PLACE, a `[[target]]` doesn't exist in the vault.

```
Decision:
  Concrete concept from paper/code? → Create stub with #status/stub
  Project-level reference (methods/xxx)? → Create stub, link to project _index.md
  Vague reference ("future work")? → Remove link, add ## 待办 bullet
  Likely typo? → Fix if obvious, otherwise ask user
```

---

## 7. Classification Deadlock

**Trigger:** Classification produces 3+ equally plausible targets or 0 targets.

```
3+ targets → present top 3 with reasoning, ask user to choose
0 targets → place in 0-Inbox/fleeting/, report: "无法自动分类"
```

---

## 8. Config File Issues

| Issue | Action |
|-------|--------|
| `note-merge.json` missing | "未找到配置文件。请先运行 init-vault 创建 vault。" |
| `vault` path doesn't exist | "Vault 路径 {path} 不存在。创建它？还是修改配置？" |
| `domains` is empty | Warn: "domains 为空，分类将仅依赖通用关键词。" |
| `source_repos` entry not found on disk | Skip it, report: "仓库 {path} 不存在，已跳过" |
| Malformed JSON | "note-merge.json 格式错误，无法解析。请检查 JSON 语法。" |

---

## 9. Structure+Reference Ambiguity

**Trigger:** The source file has conflicting structural signals (e.g., Q&A markers inside what looks like a report document) or the reference check finds a URL in an unexpected context.

```
- Structure ambiguity: apply BOTH matching strategies, deduplicate overlapping units
  Example: a chat export with section headings → extract Q&A AND split by sections.
  If both produce the same unit, keep the richer version.
- Deduplication is only for derivative extracted notes. Do not delete raw snapshot content.
- If two structures preserve different reasoning paths, keep both or add both under `## 推理脉络`.
- Reference ambiguity: perform the reference check independently of structure.
  A casual-looking note with an arxiv link still gets the offer to pull the paper.
  A well-structured report with no references still gets deepen-blocked.
```
