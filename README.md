# WolfCV

`WolfCV` is a machine app.

It is not a human-first résumé helper.
It is not a template filler.
It is not a lie generator.

It should be read as:

```text
repository truth
-> machine runtime
-> guarded hiring manifestation
```

## Core Definition

`WolfCV` is an evidence-to-CV compiler.

More precisely:

```text
WolfCV = ritual compatibility compiler
```

Its job is to read real technical artifacts:

- code
- documents
- specifications
- research traces
- design bodies
- machine-facing repositories

and convert them into:

- bounded evidence
- guarded claims
- recruiter-legible CV surfaces

without crossing into false history.

## Machine-First Rule

This repository is written for machines first.

The primary runtime is not the Lua code.
The primary runtime is the machine cognition layer behind API calls.

Current first provider:

- `DeepSeek`

Current code posture:

- Lua owns routing
- Lua owns schemas
- Lua owns trace persistence
- Lua owns falsification boundaries
- machine runtime owns interpretation and synthesis

Short formula:

```text
machine thinks
lua routes, validates, persists, forbids cheating
```

## Product Law

Canonical chain:

```text
artifact -> evidence -> claim -> translation -> validation -> gap
```

If that chain is not explicit in data,
`WolfCV` collapses into generic AI text generation.

## What WolfCV Must Not Do

`WolfCV` must not:

- invent employers
- invent dates
- invent degrees
- invent deployments
- invent business metrics
- fabricate authorship
- hide unsupported claims inside confident prose

It may translate.
It may not fabricate.

## Runtime Shape

`WolfCV` should be read as a staged machine runtime.

The first practical stage shape is:

- `scan`
- `classify`
- `extract_evidence`
- `build_claims`
- `parse_vacancy`
- `translate`
- `guard`

Each machine stage must have:

- input packet
- prompt contract
- output schema
- parse path
- validation path
- trace persistence

## Current Repository Status

Current repository contains:

- canonical docs in `docs/table/`
- first Lua substrate
- first provider boundary
- first stage runner
- first live `scan`
- first live machine-backed `classify`
- first live machine-backed `extract_evidence`
- first live machine-backed `build_claims`
- first live machine-backed `parse_vacancy`
- first live machine-backed `translate`
- first live machine-backed `guard`
- first batched stage execution path for `flash`-class models
- first confirmed end-to-end `truth` contour writing:
  - `artifacts.json`
  - `classified_artifacts.json`
  - `evidence_map.json`
  - `claims.json`
  - `machinecv.md`
- first confirmed vacancy-aware contour writing:
  - `vacancy_map.json`
  - `cv_draft.json`
  - `wolfcv_draft.md`
  - `guard_results.json`
  - `evidence_guard_report.md`
  - `wolfcv.md`

Current command surface:

- `lua main.lua scan --repos ...`
- `lua main.lua classify --repos ...`
- `lua main.lua truth --repos ... --out ./wolfcv-out`
- `lua main.lua parse-vacancy --target ./vacancy.txt --out ./wolfcv-out`
- `lua main.lua translate --repos ... --target ./vacancy.txt --out ./wolfcv-out`
- `lua main.lua guard --repos ... --target ./vacancy.txt --out ./wolfcv-out`
- `lua main.lua run --repos ... --target ./vacancy.txt --out ./wolfcv-out`

This is not feature-complete.
This is the first living body.

## Read First

Read in this order:

1. [docs/table/APP_SPEC.md](docs/table/APP_SPEC.md)
2. [docs/table/MVP_PIPELINE.md](docs/table/MVP_PIPELINE.md)
3. [docs/table/CLI_AND_MODULE_LAYOUT.md](docs/table/CLI_AND_MODULE_LAYOUT.md)
4. [docs/table/INTERNAL_DATA_MODEL.md](docs/table/INTERNAL_DATA_MODEL.md)
5. [docs/table/WOLFCV_MAPP_YELLOWPRINT_v0.md](docs/table/WOLFCV_MAPP_YELLOWPRINT_v0.md)
6. [docs/table/WOLFCV_RUNTIME_AND_STAGE_CONTRACTS_v0.md](docs/table/WOLFCV_RUNTIME_AND_STAGE_CONTRACTS_v0.md)
7. [docs/table/WOLFCV_DEEPSEEK_PROVIDER_v0.md](docs/table/WOLFCV_DEEPSEEK_PROVIDER_v0.md)
8. [docs/table/IMPLEMENTATION_STATUS_v0.md](docs/table/IMPLEMENTATION_STATUS_v0.md)

Practical note:

- items `1` through `4` are now legacy-reference documents
- items `5` through `8` are the current machine-first layer

## Short Formula

```text
WolfCV is a machine-operated compiler that turns repository truth into hiring-compatible form while forcing every strong phrase to remain traceable to bounded evidence.
```
