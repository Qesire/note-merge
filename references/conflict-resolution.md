# Conflict Resolution

Structured de-duplication conflict resolution during the `merge` Phase 4.

---

## When Conflicts Occur

During `merge`, Phase 4 (DE-DUPLICATE) checks each extracted unit against the vault:
1. Exact title match → conflict
2. Semantic overlap (same paper title, same concept name) → conflict
3. Both exist → present choices

---

## Decision Matrix

| Condition | Suggested Action | Confidence | Rationale |
|-----------|-----------------|------------|-----------|
| New note is **longer** AND has **more references/links** | REPLACE | High | Newer content is more complete |
| Existing note is `polished` AND new note is `draft` | SKIP | High | Don't overwrite completed work |
| Both are similar length AND content overlaps <30% | MERGE | High | Complementary content |
| Exact same title but different topic/area | KEEP BOTH | High | False match — use `_v2` suffix |
| Existing note is `stub` AND new note has >200 words | REPLACE | High | New note fills the stub |
| New note has experiment data, existing is pure concept | MERGE | Medium | Add experiment as new section |
| Both are short (<100 words) AND highly similar (>80%) | MERGE | Medium | Combine into one comprehensive note |
| Creation dates differ by >6 months | KEEP BOTH | Low | Significant time gap may indicate different context |

---

## Conflict Comparison Format

When presenting a conflict to the user, show:

```
═══════════════════════════════════════════════════════════
CONFLICT: MXFP4-Format.md
═══════════════════════════════════════════════════════════

  EXISTING                             NEW
  ────────                             ───
  Title: MXFP4 Format                  Title: MXFP4 格式
  Tags: [concept, quantization,        Tags: [concept, quantization,
         mxfp4, draft]                        mxfp4, draft]
  Words: 340                           Words: 520
  Created: 2026-05-15                  Created: 2026-06-01
  Links: 3                             Links: 5
  Status: draft                        Status: draft
  Sections: 定义, 为什么重要             Sections: 定义, 为什么重要,
                                                 关联概念, 实验证据

  OVERLAP: 45% (shared sections: 定义)

═══════════════════════════════════════════════════════════
  SUGGESTION: REPLACE (Confidence: High)
  REASON: New note is 1.5x longer and has 2 additional
          sections with experiment evidence.

  [R] REPLACE    [M] MERGE    [S] SKIP
  [K] KEEP BOTH  [C] CUSTOM   [A] APPLY-TO-ALL-SIMILAR
═══════════════════════════════════════════════════════════
```

### Fields explained

| Field | Source |
|-------|--------|
| Title | H1 heading or filename |
| Tags | YAML frontmatter `tags:` field |
| Words | `wc -w` on content body (excluding frontmatter) |
| Created | `created:` in frontmatter, or file mtime |
| Links | Count of `[[wikilinks]]` in content |
| Status | `#status/*` tag from frontmatter |
| Sections | H2 headings in content |
| Overlap | Jaccard similarity of H2 section titles as percentage |

---

## Merge Strategy (when user selects MERGE)

```
Merge rules:
  1. Use the existing note's filename and title
  2. Keep existing note's frontmatter, merge tags: union both tag sets
  3. Update source: frontmatter field to include both sources
  4. For each H2 section:
     - If section exists in both → append new content to existing section
       with a "## (merged from <source>)" sub-heading
     - If section exists only in new → append as new section
     - If section exists only in existing → keep as-is
  5. Merge ## 来源 sections: concatenate both with sources
  6. Merge ## 关联概念 sections: deduplicate [[links]]
  7. Update created: keep the earliest date
  8. Update status: use the higher status (stub < draft < polished)
```

---

## Batch Conflict Mode

When the user selects `[A] APPLY-TO-ALL-SIMILAR`:

1. Record the decision rule (e.g., "if new is longer, REPLACE")
2. Apply to all subsequent conflicts matching the same pattern
3. Show a summary at the end:
   ```
   Auto-resolved by rule "newer+longer → REPLACE":
     MXFP4-Format.md → REPLACE
     Block-Rotation.md → REPLACE
     PTQ-Basics.md → SKIP (existing is polished)

   Manual resolution needed:
     Adaptive-Rounding.md (new has experiment data, not longer)
   ```

---

## Keep Both Strategy

When selecting KEEP BOTH:
- Existing note: stays as-is
- New note: saved as `<OriginalName>_v2.md` (or `_v3`, `_v4`, etc.) in same directory
- A `## 变体说明` section is added to one note explaining the difference
- Both notes cross-link each other in `## 关联概念`

---

## Interactive Flow in the Skill

When `resolve` action is invoked (or during `merge` Phase 4):

```
For each conflict:
  1. Read both files (existing + new)
  2. Generate comparison view
  3. Compute decision matrix → get suggestion
  4. Present to user
  5. Wait for user input (single character: R/M/S/K/C/A)
  6. Execute action
  7. If MERGE: follow merge strategy rules above
  8. Log decision to state
  9. Proceed to next conflict
```
