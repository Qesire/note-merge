# Batch Operations

Run actions across many notes with checkpoint/recovery support.

---

## Checkpoint Mechanism

All batch write operations use a state file at `~/KnowledgeBase/.note-merge-state.json`:

```json
{
  "action": "batch-deepen",
  "target_dir": "2-Areas/Quantization/",
  "started": "2026-06-01T14:00:00",
  "updated": "2026-06-01T14:15:00",
  "completed": ["MXFP4-Format.md", "Block-Rotation.md"],
  "failed": {
    "Adaptive-Rounding.md": "No source files found to trace"
  },
  "skipped": {
    "Quantization-Basics.md": "Already status/polished"
  },
  "pending": ["PTQ-vs-QAT.md"],
  "current": null
}
```

**Rules:**
- State file is updated after every individual note is processed (atomic writes)
- On resume, read state file and skip `completed` items
- On completion, rename state file to `.note-merge-state.json.done`
- If state file exists but action is different, ask user before overwriting

---

## Sub-Actions

### `batch deepen <dir>`

Deepen all concept notes with `#status/stub` or `#status/draft` in a directory.

```
Process for each note:
  1. Read the note → check status tag
  2. If status/polished → skip
  3. Collect referenced source files from frontmatter/references
  4. Run full 5-layer deepening (see references/concept-deepening.md)
  5. Update tags: stub/draft → polished, add deepened: date
  6. Update _index.md MOC if needed
  7. Write state checkpoint
```

**Options:**
- `batch deepen <dir> --all` — also re-deepen already-polished notes
- `batch deepen <dir> --dry-run` — list which notes would be deepened, don't write

### `batch format <dir>`

Apply formatting to all notes in a directory.

```
Process for each note:
  1. Read note → check current format state
  2. Ensure YAML frontmatter has tags: and created:
  3. Normalize heading hierarchy (H1 title, H2 sections)
  4. Add ## 来源 section if missing
  5. Remove extra whitespace (>2 consecutive blank lines)
  6. Ensure all internal links use [[wikilinks]]
  7. Write state checkpoint
```

**Options:**
- `batch format <dir> --fix-links` — also fix broken/dead wikilinks
- `batch format <dir> --dry-run` — report issues only, don't write

### `batch classify <dir>` — Read-only

Pre-classify all raw files in a directory and output a classification plan.

```
Output format (CSV-like table):

  File | Type | Suggested PARA | Suggested Filename | Confidence
  chat_export_0601.md | chat-export | 0-Inbox/fleeting/ | multiple (see breakdown) | -
  paper_notes_raw.md | paper-note | 3-Resources/Papers/diffusion/ | DDIM-Sampling.md | High
  experiment_log.txt | experiment-log | 1-Projects/TinyFusion/experiments/ | fusion-block-test.md | Medium
```

### `batch link-check` — Read-only

Scan all vault files and report every broken `[[wikilink]]`.

```
Output format:
  File | Line | Broken Link | Suggestion
  MXFP4-Format.md | 42 | [[Block-Rotaton]] | Did you mean [[Block-Rotation]]?
  PTQ-vs-QAT.md | 15 | [[Adaptive-Rounding]] | Stub needed or file missing
```

### `batch re-index`

Regenerate all `_index.md` MOC files. For each directory in `1-Projects/` and `2-Areas/`:

```
Process:
  1. List all .md files in directory (excluding _index.md itself)
  2. Read frontmatter from each to get type/status/title
  3. Write _index.md with categorized links:
     ### 概念笔记 → [[Concept1]], [[Concept2]]
     ### 实验记录 → [[Experiment1]]
     ### 子项目 → [[Subproject1]]
  4. Preserve any custom content between ## Custom markers
```

**Custom content preservation:**
```
## 目标              ← Preserved
...                   ← Preserved
## <!-- CUSTOM END -->  ← Marker

## 概念笔记           ← Auto-generated
- [[Concept1]]
```

---

## `track` Sub-Actions

### `track scan`

Run a full vault health scan and append results to `~/KnowledgeBase/.vault-health.json`.

**Scan metrics collected:**

```json
{
  "timestamp": "2026-06-01T14:00:00",
  "totals": {
    "notes": 247,
    "by_status": {
      "draft": 120,
      "stub": 34,
      "polished": 58,
      "active": 10,
      "toread": 20,
      "archived": 5
    },
    "by_type": {
      "concept": 80,
      "paper": 60,
      "experiment": 45,
      "moc": 22,
      "daily": 30,
      "codebase": 10
    },
    "by_para": {
      "0-Inbox": 50,
      "1-Projects": 80,
      "2-Areas": 47,
      "3-Resources": 55,
      "4-Archives": 15
    }
  },
  "health": {
    "broken_links": 12,
    "broken_links_list": [
      {"source": "MXFP4-Format.md:42", "target": "Block-Rotaton", "suggestion": "Block-Rotation"}
    ],
    "moc_coverage_pct": 78.5,
    "mocs_missing_entries": [
      {"moc": "2-Areas/Quantization/_index.md", "missing": ["New-Concept.md"]}
    ],
    "stale_drafts": 23,
    "stale_drafts_list": ["note1.md", "note2.md"],
    "orphan_notes": 8,
    "orphan_notes_list": ["note3.md", "note4.md"],
    "avg_quality_score": 85.2,
    "missing_frontmatter": 3,
    "missing_frontmatter_list": ["note5.md", "note6.md"]
  },
  "delta": null
}
```

The `delta` field is populated by `track diff`, not by `track scan`.

### `track report`

Print the most recent scan as a formatted report:

```
Vault Health Report — 2026-06-01 14:00
═══════════════════════════════════════

  Total Notes: 247
    Draft: 120  Stub: 34  Polished: 58  ToRead: 20  Active: 10  Archived: 5
    Concepts: 80  Papers: 60  Experiments: 45  MOCs: 22  Dailies: 30

  Health Issues:
    Broken Links:      12 ⚠
    MOC Coverage:      78.5% ⚠ (missing 3 entries)
    Stale Drafts:      23 ⚠
    Orphan Notes:       8
    Avg Quality:       85.2
    Missing Frontmatter: 3 ⚠

  Top Priorities:
    1. Fix 12 broken links
    2. Add 3 missing MOC entries
    3. Review 23 stale drafts (>30 days)
```

### `track diff`

Compare the last two scans and report deltas:

```
Vault Health Delta — 2026-05-25 → 2026-06-01
══════════════════════════════════════════════

  Notes: 240 → 247 (+7)
    New: 7  Archived: 0
    Draft: 125 → 120 (-5)  Stub: 38 → 34 (-4)  Polished: 52 → 58 (+6)

  Health Changes:
    Broken Links:    15 → 12 (-3) ✅
    MOC Coverage:    76% → 78.5% (+2.5) ✅
    Stale Drafts:    28 → 23 (-5) ✅
    Orphan Notes:    10 → 8 (-2) ✅
    Avg Quality:     83.1 → 85.2 (+2.1) ✅
```

### `track trend`

ASCII line chart of key metrics over the last N scans (default 10):

```
  Notes ──────────────────────────────────
  250 │
  240 │     ●───●───●
  230 │ ●───●
      └─────────────────────────────────
        scan1  scan2  scan3  scan4  scan5

  Polished ──────────────────────────────
   60 │               ●
   55 │         ●───●
   50 │ ●───●───●
      └─────────────────────────────────

  Broken Links ──────────────────────────
   18 │ ●
   15 │   ●───●───●
   12 │           ●
      └─────────────────────────────────
```

---

## Safety Rules for Batch Operations

1. **Always `--dry-run` first** — preview what will change before writing
2. **Checkpoint after every file** — if interrupted, resume from last completed
3. **Never delete** — move to `4-Archives/` instead of removing files
4. **Report skipped items** — always explain why something was skipped
5. **Ask before large changes** — if >20 files would change, ask for confirmation
