# Vault Check

Full specification for the `check` and `archive` commands.

---

## CHECK

```
check [path]
```

Scan the vault (or a subdirectory) for issues. Do not auto-fix unless user says "fix it."

### Scoped Check

If a path argument is provided (e.g., `check 2-Areas/<Domain>/`), only scan notes under that path. Useful for focused maintenance.

### Check Items

#### 1. Broken Wikilinks

**Method:** 
- Grep all `.md` files for `[[...]]` patterns
- Extract unique link targets
- For each target, check if a corresponding `.md` exists in the vault (case-insensitive basename match)
- Count how many notes reference each broken target

**Report:**
```
断链: [[<missing-concept>]] 被 8 篇笔记引用，目标不存在
  引用来源: 2-Areas/<Domain>/A.md, 2-Areas/<Domain>/B.md, ...
```

**Priority:** Highest — sort by incoming reference count (most-referenced missing targets first).

#### 2. Stub Notes

**Method:**
- Find all `.md` with `#status/stub` in frontmatter tags
- List with area tag and age (days since `created:`)

**Report:**
```
Stub 笔记: 12 篇，可考虑 deepen
  - [[<concept-1>]] (area/<domain>, 15天)
  - [[<concept-2>]] (area/<domain>, 42天)
```

**Priority:** High.

#### 3. Orphan Notes

**Method:**
- Build a set of all note basenames that appear as `[[targets]]` in the vault
- Find all `.md` files whose basename is NOT in that set
- Exclude `_index.md`, MOC files, and template files

**Report:**
```
孤儿笔记: 5 篇，没有 incoming wikilink
  - 3-Resources/Code-Tools/<tool>.md
  - ...
```

**Priority:** Medium.

#### 4. Stale Drafts

**Method:**
- Find all `.md` with `#status/draft`
- Check `modified:` frontmatter field (preferred) or file mtime (fallback)
- Flag if >30 days since modification

**Report:**
```
过期 draft: 3 篇，超过 30 天未修改
  - [[Old-Experiment]] (modified: 2026-04-01, 62天)
  - ...
```

**Priority:** Medium.

#### 5. Stale To-Read Papers

**Method:**
- Find all `.md` with `#status/toread`
- Check `modified:` or `created:` field
- Flag if >60 days since creation with no status change

**Report:**
```
积压 toread: 4 篇，超过 60 天未阅读
  - [[<paper-name>]] (created: 2026-03-01, 93天)
  - ...
```

**Priority:** Medium.

#### 6. Missing Frontmatter

**Method:**
- For each `.md` in the vault (excluding `_templates/` and `.obsidian/`):
  - Check for `tags:` in YAML frontmatter
  - Check for `created:` in YAML frontmatter
  - Check for `modified:` in YAML frontmatter (warn only, not a hard error)

**Report:**
```
Frontmatter 缺失: 2 篇
  - 0-Inbox/fleeting/untitled.md: 缺少 tags, created, modified
  - 2-Areas/X/note.md: 缺少 modified
```

**Priority:** Low.

#### 7. Inconsistent Status

**Method:**
- Find notes that have 5-layer deepened structure (## 1. 动机, ## 2. 机制, etc.) but are still tagged `#status/draft`
- Find notes tagged `#status/polished` that lack the 5-layer structure

**Report:**
```
状态不一致: 2 篇
  - [[Deep-Note-Still-Draft]]: 有5层结构但标签为 draft
  - [[Shallow-Polished]]: 标签为 polished 但无5层结构
```

**Priority:** Low.

#### 8. Config Health

**Method:**
- Read `note-merge.json`
- For each path in `source_repos`: check if it exists on disk
- For each domain in `domains`: check if `2-Areas/<Domain>/` exists
- Check if `vault` path exists
- Check if `domains` is empty

**Report:**
```
配置问题:
  - source_repos 中 ~/<old-repo> 不存在
  - 2-Areas/<NewDomain>/ 目录不存在 (在 domains 中声明)
```

**Priority:** Low (but reported first if found, since config issues affect all operations).

### Output Format

```
Vault 检查 — YYYY-MM-DD
════════════════════════════
高优先级
- 断链: [[<missing-concept>]] 被 8 篇笔记引用，目标不存在
- 配置问题: source_repos 中 ~/<old-repo> 不存在

中优先级
- Stub 笔记: 12 篇
- 过期 draft: 3 篇（>30天）
- 积压 toread: 4 篇（>60天）

低优先级
- 孤儿笔记: 5 篇
- Frontmatter 缺失: 2 篇
- 状态不一致: 2 篇

建议:
- 3 篇 stub 有可追溯来源，可批量 deepen: deepen --all-stubs
- 1-Projects/OldProject 已 90 天无更新，考虑归档: archive 1-Projects/OldProject
```

### Auto-fix

When user says "fix it" or similar:

| Issue | Auto-fix action |
|-------|-----------------|
| Broken wikilinks (typo) | If obvious typo, fix and report. Otherwise skip. |
| Missing frontmatter | Add `tags:`, `created:`, `modified:` with best-guess values, report each |
| Inconsistent status | If 5-layer structure present → change to `status/polished`. Otherwise → change to `status/draft` |
| Other | No auto-fix. List what user should do. |

Always report what was changed. Never auto-fix broken wikilinks by creating stubs without user confirmation.

---

## ARCHIVE

```
archive <note-or-directory>
```

Move a completed note or project directory into `4-Archives/`.

### Rules

1. Only archive notes/directories that are `#status/polished` or `#status/active` with no recent modification (>60 days)
2. Move the file/directory to `4-Archives/<original-relative-path>/`
3. Replace the original location with a stub containing a redirect wikilink:

```markdown
---
tags: [type/redirect]
archived_to: 4-Archives/<path>
created: <original-created>
modified: YYYY-MM-DD
---
# {{title}}

已归档 → [[4-Archives/<path>/{{title}}]]
```

4. Update all MOC files that referenced the original path
5. Report what was moved and which MOCs were updated
6. Never archive notes that are the target of broken wikilinks (fix those first)
