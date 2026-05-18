# WolfCV :: Output Surfaces v0

## Status

Pencil document.

This document exists because `WolfCV` is no longer only a machine pipeline.
It is starting to become a user-facing tool.

That means outputs must be named as surfaces,
not only as residue files.

---

## 1. Why output surfaces matter

If every output is treated the same way,
the user sees a pile of files.

But the outputs do different jobs:

- some explain truth
- some explain the vacancy
- some manifest a CV
- some expose distrust
- some are machine residue

So the product must distinguish these surfaces clearly.

---

## 2. Surface classes

### A. Truth surface

Primary artifact:

- `machinecv.md`

Role:

- show what the machine believes is safely supported by repo evidence

This is not recruiter polish.
It is the truth substrate.

---

### B. Target surface

Primary artifact:

- `vacancy_diagnosis.md`

Role:

- explain what the vacancy actually seems to ask for
- separate role shape from ritual wording

This is the mirror-image half of the translator.

---

### C. Translation surface

Primary artifact:

- `wolfcv.md`

Supporting draft:

- `wolfcv_draft.md`

Role:

- present a vacancy-aware CV manifestation

This is the visible hiring-facing output.

---

### D. Distrust surface

Primary artifact:

- `evidence_guard_report.md`

Role:

- show where wording was risky
- show where support was weak
- show where the system distrusted claims or projection

This surface is part of trust,
not an embarrassing debug leftover.

---

### E. Machine residue surface

Artifacts:

- `artifacts.json`
- `classified_artifacts.json`
- `evidence_map.json`
- `claims.json`
- `vacancy_map.json`
- `guard_results.json`
- traces

Role:

- audit
- debugging
- future automation

These are not the first reading surfaces for normal use,
but they remain essential.

---

## 3. Surface hierarchy

For product use,
the user should think in this hierarchy:

```text
vacancy_diagnosis.md
machinecv.md
wolfcv.md
evidence_guard_report.md
```

Everything else is deeper inspection.

---

## 4. Output quality states

Each surface should eventually be able to reflect quality state.

At minimum:

- `solid`
- `partial`
- `degraded`

The vacancy side already began to expose this through:

- `diagnosis_quality`
- `contract_warnings`

Equivalent quality language should eventually exist for:

- truth extraction
- translation quality
- guard severity

---

## 5. What should happen later

Later the product may split surfaces more clearly into:

- `machinecv`
- `hrcv`
- `techcv`
- `cover_note`
- `gap_report`

But that should happen only after the current four surfaces become stable.

---

## 6. Short formula

```text
WolfCV should not dump files.
It should expose a small set of named surfaces with distinct roles.
```
