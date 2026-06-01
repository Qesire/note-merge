# Concept Deepening (概念深化)

Apply the 5-layer analytical framework when the user asks to deepen existing concept notes (深化笔记, 深挖).

This framework is **domain-agnostic**. It works for any knowledge domain — sciences, engineering, humanities, arts, business — as long as the concept note has traceable references (see Layer checks below). The examples in this document are illustrative; adapt the concrete verification methods to the domain of the note being deepened.

---

## The 5-Layer Framework

For each concept, answer these questions in order:

```
Layer 1: 动机 (Motivation)
  → What specific problem does this concept solve?
  → What breaks if you remove/disable it?
  → What context, constraint, or prior work makes this necessary?

Layer 2: 机制 (Mechanism)
  → How does it work? (step-by-step)
  → What are its components, inputs, outputs, and internal state?
  → Where is it implemented or instantiated? (file:line, section, artifact reference)

Layer 3: 设计理由 (Design Rationale)
  → Why this approach over alternatives?
  → Why these specific parameters, defaults, or design choices?
  → What trade-offs were made and why?

Layer 4: 必要性验证 (Evidence)
  → What concrete evidence supports the claims about this concept?
  → Under what conditions does it work, and when does it fail?
  → Quantified results: measurements, benchmarks, comparisons, case studies

Layer 5: 系统性 (System Coupling)
  → Upstream: what feeds into this concept?
  → Downstream: what depends on this concept?
  → Cross-references: links to other concept notes, projects, papers
```

---

## Deepening Workflow

```
EXISTING NOTE (status/stub or status/draft in 2-Areas/)
       │
       ▼
Step 1: SOURCE TRACE — read all source files and references cited in the note
       │
       ▼
Step 2: CROSS-REFERENCE — read related concept notes for coupling links
       │
       ▼
Step 3: EVIDENCE GATHERING — locate experiments, data, benchmarks, or other evidence
       │
       ▼
Step 4: REWRITE — restructure note with 5-layer headings, preserving all references
       │
       ▼
Step 5: LINK — add [[wikilinks]] to upstream/downstream concept notes
       │
       ▼
Step 6: TAG — update status from stub/draft → polished
```

---

## Source Tracing (Layer 2)

When deepening, trace the concept back to its primary sources:

1. **Identify reference types in the note:**
   - Source code files/paths → search `source_repos` from `note-merge.json`
   - Academic papers → retrieve via arXiv, DOI, or URL
   - Books, articles, primary documents → locate by citation
   - Data, experiments, benchmarks → find scripts, logs, results files

2. **For code-based concepts:**
   - Search `source_repos` for files whose names or content match the concept name and related keywords
   - Read the implementation, configuration, and test files
   - Trace how the concept is instantiated and used across the codebase
   - Record exact file:line references for key definitions and usages

3. **For paper-based concepts:**
   - Locate the original paper and any follow-up work
   - Extract the formal definition, methodology section, and results
   - Note which sections/figures/tables are most relevant

4. **For other domains:**
   - Follow the same principle: locate the primary source, read the relevant sections, record references
   - Adapt the "file:line" mapping to whatever citation format is natural for the domain (page numbers, section IDs, timestamps, etc.)

5. **General rule:**
   - Always cite the exact location within the source (file:line, page:paragraph, timestamp, etc.)
   - Map between formal description and concrete implementation/instantiation
   - If implementation files exist but are outside `source_repos`, ask the user for the path

---

## Design Rationale Heuristics (Layer 3)

When analyzing why a design decision was made, ask these questions. They apply across domains; choose whichever are relevant to the concept at hand.

| Question | Applies to |
|----------|-----------|
| Why this specific approach over named alternatives? | Any design decision |
| Why these parameter values / defaults / thresholds? | Algorithm, system, or method parameters |
| What constraint drove this choice? (performance, cost, compatibility, simplicity, convention) | Any trade-off |
| What would happen if a different choice were made? | Comparative analysis |
| Is there a precedent or standard that influenced this design? | Conventions, protocols, formats |
| Does this choice couple or decouple the concept from its context? | Architecture, interfaces |

For each answer, cite concrete evidence (benchmark, paper claim, design doc, standard, etc.). Do not rely on unsourced reasoning.

---

## Evidence Standards (Layer 4)

Evidence requirements vary by domain. Adapt the evidence bar to the field:

| Domain type | Valid evidence includes |
|-------------|----------------------|
| Experimental science / engineering | Named experiments with numeric metrics, ablation studies, benchmark results |
| Formal / theoretical work | Proofs, theorems, formal verification results, complexity analysis |
| Empirical / observational | Datasets, surveys, case studies, field observations with documented methodology |
| Historical / textual | Primary sources, archival records, text-critical analysis, corroborating documents |
| Design / creative | Prototypes, user studies, critiques, precedent analysis, iteration history |
| Business / strategy | Market data, financial results, A/B tests, case outcomes |

**Universal evidence rules:**
- Every claim must cite a specific source (experiment name, paper section, dataset, document)
- Quantitative claims need numbers; qualitative claims need documented examples
- "效果好", "效果显著", "greatly improves" without specific source → FAIL
- Absence of evidence must be noted, not papered over

---

## Cross-Reference Rules (Layer 5)

Every deepened note MUST include `[[links]]` to:

1. **Upstream concepts** — what feeds into it, what it depends on
2. **Downstream concepts** — what depends on it, what it enables
3. **Related projects** — which projects implement, apply, or use it
4. **Related papers/sources** — which papers introduced, analyzed, or challenged it
5. **Source files/artifacts** — the concrete things that instantiate it (inline references preserved from Layer 2)

Each link must be accompanied by at least one sentence explaining the relationship, not just a bare wikilink.

---

## Quality Gate

Before marking a deepened note as `#status/polished`, verify every layer meets the following sufficiency standards. A claim is "sufficient" only if it meets the specific evidence bar below — vague or generic statements count as FAIL.

### Per-Layer Sufficiency Thresholds

| Layer | Minimum Requirement | How to Verify | Common Failures |
|-------|--------------------|---------------|-----------------|
| **L1 动机** | Must cite a SPECIFIC problem, context, or constraint that makes this concept necessary. Must include at least one causal statement: "If X were removed/unavailable, Y would break/degrade because Z." | Count causal statements: must have ≥ 1. Check if the cited problem is concrete (e.g., "gradient instability in layer 12 of this architecture") not generic (e.g., "training is hard"). | "This solves the error problem" — too vague. "Without this mechanism, the variance across channels (measured at σ=3.4) would cause uneven behavior, corrupting downstream outputs" — sufficient. |
| **L2 机制** | Must have ≥ 1 specific location reference to the primary source (file:line, paper section, book page, timestamp). Step-by-step description must have ≥ 5 distinct steps showing data/state flow. Formal-to-concrete mapping table must have ≥ 1 row. | Grep the note for location references (file:line patterns, section numbers, page numbers). Count distinct steps. Count mapping rows. | "1. input → 2. process → 3. output" — 5 steps minimum. No location reference at all — source trace was not done. |
| **L3 设计理由** | Must compare ≥ 2 named alternatives with ≥ 1 specific, reasoned trade-off each. "Why this parameter value" must be answered for at least one key parameter or design choice. | Count alternatives listed by name. Check each has a concrete trade-off (number, condition, or cost statement). | "A is better than B" without saying WHY — fail. "threshold=0.5 was chosen because it balances precision (0.87) and recall (0.82) on the validation set" — sufficient. |
| **L4 证据** | Must cite ≥ 1 specific piece of evidence by name (experiment, paper, dataset, case) with ≥ 1 concrete result (numeric metric, documented finding, source quote). May NOT use phrases like "效果显著", "明显提升", or any unsourced qualitative judgment as evidence. | Check if evidence source is named. Check if result is concrete. | "实验表明效果很好" — fail, no named source, no numbers. "On the XYZ benchmark, accuracy improved from 0.72 to 0.81 (±0.02, n=5 runs)" — sufficient. |
| **L5 耦合** | Must have ≥ 2 upstream links (concepts this depends on) AND ≥ 2 downstream links (concepts depending on this). All target files must exist (no broken wikilinks). Each relationship must be EXPLAINED with ≥ 1 sentence. | Count `[[upstream]]` and `[[downstream]]` links. Verify each target file exists. Check for explanation text. | Just listing `[[ConceptA]]` under "上游" with no text explaining the relationship — fail. Links to non-existent files — fail. |

### Final Quality Checklist

Before accepting a deepened note, verify ALL of the following:

```
Layer 1 (动机):
  [ ] Contains a specific, named problem/context/constraint
  [ ] Contains at least one causal "if removed/unavailable, then..." statement
  [ ] Does NOT use vague problem statements without concrete qualification

Layer 2 (机制):
  [ ] At least 1 location reference to the primary source (file:line, section, page, timestamp)
  [ ] Step-by-step description has at least 5 distinct steps with clear flow
  [ ] At least 1 row in the formal description → concrete implementation/instantiation mapping

Layer 3 (设计理由):
  [ ] At least 2 named alternatives are compared
  [ ] At least 1 trade-off has a specific, reasoned justification
  [ ] At least 1 key parameter or design choice is justified

Layer 4 (证据):
  [ ] At least 1 named evidence source cited (experiment, paper section, dataset, document)
  [ ] At least 1 concrete result (numeric or documented qualitative)
  [ ] NO unsourced qualitative claims ("效果显著", "明显改善", "greatly improves")

Layer 5 (耦合):
  [ ] At least 2 upstream [[wikilinks]], each with ≥ 1 sentence explaining the relationship
  [ ] At least 2 downstream [[wikilinks]], each with ≥ 1 sentence explaining the relationship
  [ ] NO broken wikilinks (all target files exist)

Meta:
  [ ] Tags include status/polished
  [ ] Frontmatter includes created date
  [ ] Frontmatter includes at least one #technique/ or #topic/ tag relevant to the domain
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
