# WolfCV — MVP pipeline v0.1

## Status

Working canonical draft.

This document defines the first end-to-end executable pipeline for WolfCV.

It is intentionally narrower than the full product vision.

---

## 1. MVP goal

The first MVP should prove one thing:

```text
given a set of local repos and one vacancy,
WolfCV can produce
an evidence-grounded profile,
a guarded job-facing CV draft,
and a report of what is unsafe or missing.
```

If it can do that, the core product loop is real.

---

## 2. MVP inputs

Mandatory:

- one or more local repository paths
- one vacancy text file
- one output directory

Optional:

- candidate notes
- forbidden claim list
- include/exclude path rules

---

## 3. MVP outputs

Mandatory:

- `artifacts.json`
- `evidence_map.json`
- `claims.json`
- `vacancy_map.json`
- `machinecv.md`
- `wolfcv.md`
- `evidence_guard_report.md`

Optional:

- `legacyhrcv_report.md`
- `gap_report.md`
- `delta_report.md`

---

## 4. Canonical MVP stages

WolfCV MVP should execute these stages in order:

```text
1. repo ingest
2. artifact inventory
3. artifact classification
4. evidence extraction
5. claim building
6. vacancy parsing
7. machinecv generation
8. wolfcv generation
9. evidence guard validation
10. optional gap planning
```

---

## 5. Stage definitions

### 5.1 Repo ingest

Input:

- local paths

Output:

- repository records
- file tree

Responsibilities:

- resolve absolute paths
- verify repos exist
- capture repo metadata
- capture file paths

No summarization yet.

---

### 5.2 Artifact inventory

Input:

- raw file tree

Output:

- artifact records

Responsibilities:

- create one artifact per relevant file
- record path, extension, repo, language guess
- mark binary / ignorable / generated files

This stage is structural, not interpretive.

---

### 5.3 Artifact classification

Input:

- artifact records

Output:

- classified artifacts

Responsibilities:

- assign classes like `CODE`, `SPEC`, `DESIGN`, `RESEARCH`
- attach preliminary role tags
- attach confidence for classification

This stage should remain cheap and auditable.

---

### 5.4 Evidence extraction

Input:

- classified artifacts

Output:

- evidence records

Responsibilities:

- summarize support-bearing observations
- keep them local and factual
- attach source artifact ids
- attach limitations
- attach strength and scope

Critical rule:

```text
Evidence must remain smaller than a CV claim.
```

---

### 5.5 Claim building

Input:

- evidence records

Output:

- claim records

Responsibilities:

- group evidence into candidate-usable statements
- normalize skill tags
- assign support levels
- prepare safer wording

Critical rule:

```text
Claims are the unit that EvidenceGuard judges.
```

---

### 5.6 Vacancy parsing

Input:

- vacancy text

Output:

- vacancy map

Responsibilities:

- extract title
- extract keywords
- separate hard/soft requirements
- detect seniority signals
- estimate ritualization pressure

This stage should remain heuristic in MVP.

---

### 5.7 MachineCV generation

Input:

- evidence
- claims

Output:

- `machinecv.md`

Responsibilities:

- describe actual supported profile
- list strongest roles
- list unsupported pressure areas
- keep scope limitations visible

MachineCV is the truth layer output.

---

### 5.8 WolfCV generation

Input:

- claims
- vacancy map

Output:

- `wolfcv.md`

Responsibilities:

- produce job-facing wording
- align to vacancy pressure
- choose strongest safe framing
- preserve claim linkage

WolfCV must not outrun the support layer.

---

### 5.9 EvidenceGuard validation

Input:

- claims
- wolfcv draft
- supporting evidence

Output:

- `evidence_guard_report.md`
- structured guard results

Responsibilities:

- validate each claim
- flag unsupported or forbidden phrases
- recommend safer wording

This is the minimum honesty boundary of the product.

---

### 5.10 Optional gap planning

Input:

- vacancy map
- claims
- guard results

Output:

- `gap_report.md`

Responsibilities:

- identify high-pressure unsupported areas
- propose small honest bridge projects

This can be lightweight in MVP, but should exist conceptually.

---

## 6. What MVP should not do

MVP should not attempt:

- polished ATS scoring
- universal HR realism
- automatic chronology construction
- true year-count estimation
- autonomous GitHub account crawling
- deep team/project reconstruction
- UI-heavy workflows

MVP is a compiler prototype, not a career platform.

---

## 7. Human review loop

MVP must allow human correction at several stages:

- artifact class review
- evidence deletion or rewrite
- claim rewrite
- forbidden claim override confirmation

The first version should not pretend that the machine is final authority.

---

## 8. Golden path command

Canonical user-facing command:

```bash
wolfcv run \
  --repos ./repo1 ./repo2 ./repo3 \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

This should be the main proof path.

---

## 9. MVP success test

The MVP is successful if, for one real vacancy and one real repo stack, it can:

1. produce a believable `machinecv.md`
2. produce a more legible `wolfcv.md`
3. clearly flag unsafe claims in `evidence_guard_report.md`

If those three outputs are useful, the core product loop is validated.

---

## 10. One-line definition

```text
WolfCV MVP is a local-first CLI pipeline that turns repositories into evidence, evidence into guarded claims, and guarded claims into a vacancy-facing CV draft.
```
