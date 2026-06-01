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
```

---

## 2. Reference Missing for Deepen

**Trigger:** User requests `deepen` on a note that has no traceable reference.

| Note origin | Action |
|------------|--------|
| Originated from chat-export | ✅ Allow (conversation content is reference) |
| Has `source:` in frontmatter pointing to paper/code | ✅ Allow |
| Has [[wikilinks]] to polished notes | ✅ Allow (those notes provide context) |
| Originated from casual-note with no citations | ❌ Block — reply: "这篇笔记源自随笔手记，缺乏可追溯的参考材料。无法深化。请提供论文链接、源码路径或实验数据。" |
| Has empty `## 来源` and no frontmatter `source:` | ❌ Block — same as above |

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
