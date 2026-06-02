# note-merge.json Schema

The vault config file lives at `~/KnowledgeBase/note-merge.json`. It is created during `init-vault` and read at the start of every action.

---

## Fields

### `vault`

**Type:** `string` (path, `~` expanded)
**Default:** `~/KnowledgeBase`
**Required:** yes

Absolute or home-relative path to the Obsidian vault.

```json
"vault": "~/KnowledgeBase"
```

### `domains`

**Type:** `string[]`
**Default:** `[]`
**Required:** yes

Research domains. Each domain name:

1. Becomes a `2-Areas/<Name>/` directory with its own `_index.md`
2. Is added to the keyword→directory mapping for classification (ingest Phase 3)
3. Creates `#area/<kebab-name>` tags in the tag taxonomy

**Directory naming rules:**

| Domain value | Directory name | Tag |
|-------------|----------------|-----|
| `ecology` | `Ecology` | `#area/ecology` |
| `urban-planning` | `Urban-Planning` | `#area/urban-planning` |
| `机器学习` | `机器学习` | `#area/机器学习` |
| `early-modern-history` | `Early-Modern-History` | `#area/early-modern-history` |

Rules: Title Case each word (first letter uppercase, rest lowercase), preserve hyphens, Chinese characters as-is.

```json
"domains": ["ecology", "genomics", "urban-planning"]
```

This generates directories: `2-Areas/Ecology/`, `2-Areas/Genomics/`, `2-Areas/Urban-Planning/`

### `source_repos`

**Type:** `string[]` or `null`
**Default:** `[]`
**Optional:** yes (but `deepen` will refuse without it)

Directories searched during `deepen` for source code tracing. Each path must exist on the filesystem. Symlinks are followed.

```json
"source_repos": [
  "~/<repo-1>",
  "~/<repo-2>",
  "~/<repo-3>/<subproject>"
]
```

If empty or missing, `deepen` will warn: "未配置源码仓库路径，无法追溯代码实现。请在 note-merge.json 中添加 source_repos。"

### `language`

**Type:** `"zh-CN" | "en" | "mixed"`
**Default:** `"zh-CN"`
**Required:** yes

Controls filename convention and section heading language:

| Value | Filename rule | Heading default |
|-------|--------------|-----------------|
| `zh-CN` | Chinese filenames for Chinese content | Chinese headings (动机, 机制, ...) |
| `en` | kebab-case for everything | English headings (Motivation, Mechanism, ...) |
| `mixed` | Per-file judgment based on content language | Match heading language to content |

---

## Full Example

```json
{
  "vault": "~/KnowledgeBase",
  "domains": ["ecology", "genomics", "urban-planning", "early-modern-history"],
  "source_repos": [
    "~/<repo-1>",
    "~/<repo-2>",
    "~/<repo-3>",
    "~/<repo-4>"
  ],
  "language": "zh-CN"
}
```

---

## Validation

When reading `note-merge.json`:

1. If file does not exist → prompt user to run `init-vault`
2. If `vault` path does not exist → warn, offer to create or change path
3. If `domains` is empty → warn: classification will rely only on generic keywords
4. If `source_repos` entry does not exist on disk → skip it, report: "仓库路径 {path} 不存在，已跳过"
5. If malformed JSON → report error, do not proceed
