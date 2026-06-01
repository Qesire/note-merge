# Concept Deepening (概念深化)

Apply the 5-layer analytical framework when the user asks to deepen existing concept notes (深化笔记, 深挖), or when new code is available that should be traced into concept notes.

---

## The 5-Layer Framework

For each concept, answer these questions in order:

```
Layer 1: 动机 (Motivation)
  → What specific problem does this concept solve?
  → What breaks if you remove/disable it?
  → What distribution, architecture, or data property makes this necessary?

Layer 2: 机制 (Mechanism)
  → How is it implemented? (file:line in source code)
  → Full forward-pass flow in pseudo-code
  → Math formula → code mapping

Layer 3: 设计理由 (Design Rationale)
  → Why this approach over alternatives?
  → Why these specific parameters (block_size, levels, learning rates)?
  → Trade-offs analyzed (memory vs accuracy, speed vs quality)

Layer 4: 必要性验证 (Evidence)
  → Ablation: what happens if removed? (experimental data)
  → Distribution experiments: which cases it helps, which it doesn't
  → Quantified gains: MSE reduction, SQNR improvement, speedup

Layer 5: 系统性 (System Coupling)
  → Upstream: what feeds into this concept?
  → Downstream: what depends on this concept?
  → Cross-references: links to other concept notes in 2-Areas/
```

---

## Deepening Workflow

```
EXISTING NOTE (status/stub or status/draft in 2-Areas/)
       │
       ▼
Step 1: SOURCE TRACE — read all source files referenced in the note
       │
       ▼
Step 2: CROSS-REFERENCE — read related concept notes for coupling links
       │
       ▼
Step 3: EXPERIMENT DATA — find relevant experiment scripts and their outputs
       │
       ▼
Step 4: REWRITE — restructure note with 5-layer headings, preserving all file:line refs
       │
       ▼
Step 5: LINK — add [[wikilinks]] to upstream/downstream concept notes
       │
       ▼
Step 6: TAG — update status from stub/draft → polished
```

---

## Source Code Tracing Rules

When deepening, the following must be read and referenced:

| Concept type | Required sources |
|-------------|-----------------|
| Quantization format | `mxfp4.py` (format definition) + `*_experiment.py` (distribution analysis) + `quant_layer.py` (how quantizer is used) |
| Rotation/transform | `rotations.py` + `core.py` (DartQuant) + `quarot_quant_layer.py` (ViDiT-Q variant) |
| Loss function | The loss definition + the training loop that uses it + the benchmark that compares it |
| PTQ algorithm | `adaptive_rounding.py` + `block_recon.py` + `quant_block.py` + `models.py` (for calib flow) |
| Model architecture | `models.py` (full class definitions) + `quant_block.py` (quantized variant) |
| Compression/pruning | `prune_by_score.py` (algorithm) + `train_masked_kd.py` (recovery) + `models.py` (architecture) |
| Diffusion guidance | `paper_version.py` (full pipeline) + `measurements.py` (operators) |

---

## Layer 3: Design Rationale Patterns

Common design questions to answer for each concept type:

**Numerical formats (MXFP4, INT4, etc.)**
- Why these specific representable values?
- Why block-shared scale vs per-element?
- Why this block_size? (usually power-of-2 for hardware alignment)
- Compare with alternative formats (INT4, NF4, FP8)

**Rotations (Hadamard, QR-Orth, Cayley)**
- Why block-wise vs global? (param count: C×B vs C²)
- Why orthogonal? (preserves norm → doesn't change model semantics)
- Fixed vs random vs learned trade-off table
- Block_size choice: matches quantization block_size

**Loss functions**
- Why this functional form? (exp(-|x|) vs exp(-x²) tail behavior)
- Why not directly optimize quantization MSE? (gradient issues)
- Compare with alternatives: what each optimizes, what each ignores

**PTQ algorithms**
- Why block-level vs layer-level reconstruction?
- Why temperature annealing? (soft→hard transition)
- Why dual optimizer? (weight alpha vs activation delta different loss landscapes)
- Why split calibration data to disk? (OOM prevention with batch_size calculation)

**Architecture components (adaLN, attention)**
- Why this conditioning mechanism? (concatenation vs cross-attention vs modulation)
- Why N signals? (count by submodules × types of modulation)
- Why zero-initialization? (identity-mapping start for stable training)

---

## Cross-Reference Rules

Every deepened note MUST include `[[links]]` to:

1. **Upstream concepts** — what feeds into it (e.g., Block-Rotation → MXFP4-Format)
2. **Downstream concepts** — what depends on it (e.g., MXFP4-Format → DiTQuant-Validation experiments)
3. **Related projects** — which projects implement/use it (e.g., `[[../../1-Projects/PTQ4DiT/_index|PTQ4DiT]]`)
4. **Related papers** — which papers introduced/analyzed it (e.g., `[[../../3-Resources/Papers/quantization/ptq4dit|PTQ4DiT]]`)
5. **Source code files** — the exact files that implement it (inline file:line references preserved from Layer 2)

---

## Quality Gate

Before marking a deepened note as `#status/polished`, verify every layer meets the following sufficiency standards. A claim is "sufficient" only if it meets the specific evidence bar below — vague or generic statements count as FAIL.

### Per-Layer Sufficiency Thresholds

| Layer | Minimum Requirement | How to Verify | Common Failures |
|-------|--------------------|---------------|-----------------|
| **L1 动机** | Must cite a SPECIFIC distribution property, data characteristic, or architecture constraint that makes this concept necessary. Must include at least one causal statement: "If X were removed, Y would degrade because Z." | Count causal statements: must have ≥ 1. Check if the property cited is concrete (e.g., "activation outliers in LayerNorm outputs") not generic (e.g., "quantization causes accuracy loss"). | "This solves the quantization error problem" — too vague. "Without block rotation, the per-channel variance in QKV projections (std=3.4) would be quantized unevenly, causing outlier channels to dominate MSE" — sufficient. |
| **L2 机制** | Must have ≥ 1 file:line reference to actual source code. Pseudo-code must have ≥ 5 distinct steps showing data flow. Math→code mapping table must have ≥ 1 row. | Grep the note for `:\d+` pattern (file:line). Count pseudo-code steps. Count rows in math→code table. | Pseudo-code that is just "1. input → 2. process → 3. output" — 5 steps minimum. No file:line reference at all — code trace was not done. |
| **L3 设计理由** | Must compare ≥ 2 named alternatives with ≥ 1 specific, quantified trade-off each. "Why this parameter value" must be answered for at least one key parameter. | Count alternatives listed by name. Check each has a concrete trade-off (number, condition, or cost statement). | "A is better than B" without saying WHY — fail. "block_size=32 because it's a power of 2" — marginal, add hardware alignment reasoning. |
| **L4 证据** | Must cite ≥ 1 specific experiment by name with ≥ 1 numeric metric from actual results. May NOT use phrases like "效果显著", "明显提升", or any unsourced qualitative judgment as evidence. | Grep for digits (MSE values, FID scores, percentage changes). Check if values come from a named experiment script or log. | "实验表明效果很好" — fail, no numbers. "MSE improved by 0.0023 (from 0.0081 RTN to 0.0058 w/ rotation)" — sufficient. |
| **L5 耦合** | Must have ≥ 2 upstream links (concepts this depends on) AND ≥ 2 downstream links (concepts depending on this). All target files must exist (no broken wikilinks). Upstream/downstream relationship must be EXPLAINED, not just listed. | Count `[[upstream]]` and `[[downstream]]` links. Verify each target file exists. Check for explanation text (at minimum one sentence per link). | Just listing `[[ConceptA]]` under "上游" with no text explaining the relationship — fail. Links to non-existent files — fail. |

### Final Quality Checklist

Before accepting a deepened note, verify ALL of the following:

```
Layer 1 (动机):
  [ ] Contains a specific, named distribution/architecture/data property
  [ ] Contains at least one causal "if removed, then..." statement
  [ ] Does NOT use the generic phrase "量化误差" or "accuracy loss" without qualification

Layer 2 (机制):
  [ ] At least 1 file:line reference to actual source code (e.g., mxfp4.py:128)
  [ ] Pseudo-code has at least 5 distinct steps with clear data flow
  [ ] At least 1 row in the math formula → code mapping table

Layer 3 (设计理由):
  [ ] At least 2 named alternatives are compared (e.g., "Hadamard vs QR-Orth vs Random")
  [ ] At least 1 trade-off has a specific, quantified reason (not just "better")
  [ ] At least 1 key parameter value is justified

Layer 4 (证据):
  [ ] At least 1 named experiment cited (script or log file name)
  [ ] At least 1 numeric metric from actual results (MSE, FID, SQNR, speedup %, etc.)
  [ ] NO unsourced qualitative claims ("效果显著", "明显改善", "greatly improves")

Layer 5 (耦合):
  [ ] At least 2 upstream [[wikilinks]], each with ≥ 1 sentence explaining the relationship
  [ ] At least 2 downstream [[wikilinks]], each with ≥ 1 sentence explaining the relationship
  [ ] NO broken wikilinks (all target files exist)

Meta:
  [ ] Tags include status/polished
  [ ] Frontmatter includes created date
  [ ] Frontmatter includes at least one #technique/ tag
  [ ] Frontmatter includes deepened: date
```

### Rejection Protocol

If ANY layer fails sufficiency:

```
1. Do NOT mark as status/polished
2. Do NOT fabricate missing evidence
3. Keep status as draft
4. Add a ## 深化待办 section listing exactly what's missing:
   - for each failed layer, one bullet describing what data/reading is needed
5. Report to user: "深化未完成: Layer {N} 缺少 {具体缺少的内容}。已保留为 draft，并在笔记中列出待办。"
```
