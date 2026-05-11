# WolfCV — CLI and module layout v0.1

## Status

Working canonical draft.

This document defines the first practical command surface and internal module boundaries for WolfCV.

---

## 1. CLI design principle

The CLI should be:

- simple at the top
- modular underneath
- explicit about stages
- easy to debug

Top-level user path should be one main command:

```text
wolfcv run
```

Everything else exists to inspect or debug parts of the pipeline.

---

## 2. Root command

Root binary:

```text
wolfcv
```

Not:

- `machinecv`
- `legacyhrcv`
- `guardcv`

Reason:

WolfCV is the application.
MachineCV is an internal machine.

---

## 3. MVP command set

### Main command

```bash
wolfcv run --repos ... --target vacancy.txt --out ./wolfcv-out
```

### Stage commands

```bash
wolfcv truth --repos ...
wolfcv translate --repos ... --target vacancy.txt
wolfcv guard --repos ... --target vacancy.txt
wolfcv legacy-test --repos ... --target vacancy.txt
wolfcv gap --repos ... --target vacancy.txt
```

### Lower-level utility commands

```bash
wolfcv scan --repos ...
wolfcv classify --repos ...
wolfcv extract-evidence --repos ...
wolfcv parse-vacancy --target vacancy.txt
```

These are for development and inspection, not the main user story.

---

## 4. Recommended command responsibilities

### `wolfcv run`

Runs the end-to-end pipeline and writes all configured outputs.

### `wolfcv truth`

Produces only the evidence-grounded layer:

- artifacts
- evidence
- claims
- `machinecv.md`

### `wolfcv translate`

Builds a `wolfcv.md` draft from current claim set and vacancy map.

### `wolfcv guard`

Evaluates generated claims and phrasing against evidence.

### `wolfcv legacy-test`

Runs the shallow ritual readability simulation.

### `wolfcv gap`

Produces missing-signal analysis and bridge suggestions.

---

## 5. Shared CLI arguments

MVP should support at least:

```text
--repos
--target
--out
--notes
--forbidden-claims
--include
--exclude
--format
--verbose
```

### Minimal examples

```bash
wolfcv run \
  --repos ./processcards ./packet-slop ./x112 \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

```bash
wolfcv truth \
  --repos ./processcards ./packet-slop \
  --out ./wolfcv-out
```

---

## 6. Internal module layout

Recommended first-pass layout:

```text
wolfcv/
├── cli/
├── core/
├── ingest/
├── classify/
├── evidence/
├── claims/
├── vacancy/
├── translate/
├── guard/
├── legacy/
├── gap/
├── reports/
└── schemas/
```

---

## 7. Module responsibilities

### `cli/`

Argument parsing and command routing.

Should not contain business logic.

### `core/`

Shared types, config loading, logging, path handling, orchestration helpers.

### `ingest/`

Repository discovery and artifact inventory.

### `classify/`

Artifact classification and preliminary tagging.

### `evidence/`

Evidence extraction from artifacts.

### `claims/`

Claim building, normalization, support-level assignment.

### `vacancy/`

Vacancy parsing and ritual-pressure interpretation.

### `translate/`

WolfCV wording generation and claim-to-CV assembly.

### `guard/`

EvidenceGuard evaluation and safer-wording suggestions.

### `legacy/`

LegacyHR simulation and diagnostic reporting.

### `gap/`

Gap detection and bridge-project suggestions.

### `reports/`

Markdown and JSON output writing.

### `schemas/`

Canonical data model schemas for:

- artifacts
- evidence
- claims
- vacancy
- guard results
- gaps

---

## 8. First orchestration boundary

The first implementation should have one central orchestrator:

```text
run_pipeline(config)
```

That orchestrator should call stage modules in order, rather than distributing control across the whole codebase.

This keeps MVP understandable.

---

## 9. Output writing policy

Every stage should return structured data.

Only `reports/` should decide how to write:

- markdown
- json
- plain text summaries

This avoids mixing reasoning with presentation.

---

## 10. Persistence policy

For MVP:

- JSON artifacts are first-class
- markdown reports are derived views

Meaning:

```text
json = machine substrate
markdown = human-readable projection
```

This is important for later reproducibility and testing.

---

## 11. Testing policy

The first implementation should test:

- artifact classification on known files
- evidence extraction shape
- claim traceability
- vacancy parsing basics
- guard status stability

Do not start with snapshot-testing pretty markdown only.

The core must be tested at the structured data layer.

---

## 12. MVP implementation order

Recommended coding order:

1. `schemas/`
2. `ingest/`
3. `classify/`
4. `evidence/`
5. `claims/`
6. `vacancy/`
7. `reports/`
8. `translate/`
9. `guard/`
10. `gap/`
11. `legacy/`
12. `cli/`

This order follows dependency pressure instead of feature glamour.

---

## 13. One-line definition

```text
WolfCV's CLI should expose one simple top-level workflow while keeping the internal pipeline explicitly modular, structured, and inspectable.
```
