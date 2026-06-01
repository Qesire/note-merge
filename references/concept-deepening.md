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

Before marking a deepened note as complete, verify:
- [ ] All 5 layers have non-trivial content (not placeholders)
- [ ] Every claim in Layer 4 is backed by specific experiment name + metric
- [ ] Every code reference in Layer 2 has exact file:line
- [ ] Layer 3 compares at least 2 alternatives with concrete trade-offs
- [ ] Layer 5 has at least 2 upstream and 2 downstream links
- [ ] Tags updated to `status/polished`
- [ ] Frontmatter includes `created` date and relevant `#technique/` tags
