# WolfCV :: ProcessCards QA Run Review v0

## Status

Pencil review note.

This document records the first heavy `processcards + QA vacancy` run as a product-learning artifact.

It is not a success-theater memo.
It is a data note.

---

## 1. Test case

Source:

- repo: `processcards`

Target:

- QA automation / game testing vacancy

Goal:

- test `WolfCV` on a repo that is dense, nontrivial, and verification-heavy
- see whether the machine can produce a meaningful hiring-facing projection
- learn where the truth layer overfits to repo internals

---

## 2. What the run proved

The run proved several important things at once:

- the pipeline works end-to-end on a heavy repo
- the earlier memory blow-up bug is fixed
- `processcards` is a legitimate verification / QA-signal source
- vacancy diagnosis for this role is coherent
- `hh`-shaped output is now possible

This was not a toy run.
It was a real product-learning run.

---

## 3. Main result

Final output set was produced:

- `START_HERE.md`
- `vacancy_diagnosis.md`
- `machinecv.md`
- `hhcv.md`
- `wolfcv.md`
- `evidence_guard_report.md`

This means the current machine can already:

- read repo truth
- read the vacancy
- project a guarded hiring surface
- produce a first hh-compatible draft without fake employment history

---

## 4. What went well

### A. Vacancy reading

The vacancy was read correctly as:

- `QA Automation Engineer`
- archetype: `qa_automation`
- diagnosis quality: `solid`

This is good.
The machine did not drift into generic AI-role confusion.

### B. Verification signal surfaced

The system did pick up real relevant signals from `processcards`:

- CLI automation surface
- scenario modules
- invariant checks
- smoke/bench style validation
- headless/game-state test posture

This is exactly the type of hidden candidate signal `WolfCV` is supposed to rescue.

### C. HH-compatible draft exists

`hhcv.md` exists and stays honest:

- no fake employment history
- no invented company names
- no invented dates
- project experience is used instead of fake work chronology

This is an important product milestone.

---

## 5. What went wrong

### A. Truth granularity is too low-level

`machinecv.md` became too large and too literal.

Observed:

- `215 evidence`
- `210 claims`
- `machinecv.md` around `202 KB`

This is too much for one repo in a normal candidate-facing truth layer.

The machine over-described:

- internal game mechanics
- rendering details
- small helper functions
- local semantic details of the project world

This is not hallucination.
It is over-granular truth extraction.

### B. Repo-internal semantics leaked into career surface

The machine sometimes treated:

- internal game logic
- project ontology
- mechanic-level detail

as if they were directly hiring-relevant.

This is the wrong abstraction layer.

The needed abstraction is:

- engineering pattern
- system behavior
- verification contour
- runtime shape

not repo lore.

### C. Runtime is too slow in full mode

The run took far too long for ordinary usage.

The main bottleneck was:

- `extract_evidence`

This is not fatal for `full`,
but it is not acceptable as the only product mode.

---

## 6. Product lessons

This run produced several high-value lessons:

### 6.1 Truth should be cached

Truth-layer should be treated as:

- compile artifact
- keyed by repo state / commit

not rebuilt from scratch on every vacancy.

### 6.2 Modes are mandatory

The product now clearly needs:

- `full`
- `balanced`
- `fast`
- `vacancy_only`
- `truth_only`

### 6.3 Claim aggregation is now a priority

The next real quality problem is not honesty.
It is abstraction.

The machine needs to merge many small internal facts into higher-level claims.

### 6.4 Signal ranking is needed

Not every true repo fact deserves equal prominence.

The machine needs to distinguish:

- strong candidate signal
- true but low-value implementation detail

---

## 7. What should go into the repo

Recommended to commit:

- this review document
- maybe a small curated example pack:
  - `START_HERE.md`
  - `vacancy_diagnosis.md`
  - `hhcv.md`
  - `wolfcv.md`
  - `evidence_guard_report.md`

Recommended not to commit:

- raw `artifacts.json`
- raw `classified_artifacts.json`
- raw `evidence_map.json`
- raw `claims.json`
- full trace bodies
- giant `machinecv.md` from this run

Reason:

- too noisy
- too literal
- too provider-specific
- too heavy for the repo
- not the right default reading surface for humans

Short policy:

```text
commit curated surfaces and review notes,
not raw heavy machine residue from a dense run.
```

---

## 8. Short formula

```text
This run proved that WolfCV can already see the right signal,
but it still needs to learn how to compress truth into hiring-relevant form.
```
