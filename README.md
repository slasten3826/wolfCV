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

## Human Entry

This repository is still machine-first,
but there is now a first human-facing entry path:

- [HUMAN_README.md](HUMAN_README.md)

Use that if you want the shortest explanation of:

- what `WolfCV` does
- what to feed it
- what outputs matter first

There is also a first external-use entry:

- [QUICKSTART.md](QUICKSTART.md)

## Machine-First Rule

This repository is written for machines first.

The primary runtime is not the Lua code.
The primary runtime is the machine cognition layer behind API calls.

Current first provider:

- `DeepSeek`

Current runtime posture:

- stage-specific provider/model routing now exists
- `DeepSeek` is the first live provider body
- `openai_compat` exists as the bridge for local and future third-party models

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
- first vacancy diagnosis quality surface:
  - `diagnosis_quality`
  - `contract_warnings`
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
- `vacancy_diagnosis.md`
- `cv_draft.json`
- `wolfcv_draft.md`
  - `guard_results.json`
  - `evidence_guard_report.md`
  - `wolfcv.md`

Current command surface:

- `lua main.lua scan --repos ...`
- `lua main.lua scan --github-profile slasten3826`
- `lua main.lua classify --repos ...`
- `lua main.lua classify --github-profile slasten3826`
- `lua main.lua truth --repos ... --out ./wolfcv-out`
- `lua main.lua parse-vacancy --target ./vacancy.txt --out ./wolfcv-out`
- `lua main.lua translate --repos ... --target ./vacancy.txt --out ./wolfcv-out`
- `lua main.lua guard --repos ... --target ./vacancy.txt --out ./wolfcv-out`
- `lua main.lua run --repos ... --target ./vacancy.txt --out ./wolfcv-out`

Current source ingestion:

- local repository paths via `--repos`
- public GitHub profiles via `--github-profile`
- GitHub sources are cloned into a local cache and then treated as ordinary repos by the rest of the pipeline

This is not feature-complete.
This is the first living body.

Current interpreter law:

- raw vacancy reading must first satisfy a core machine contract
- Lua may normalize and enrich the result only after that
- degraded vacancy readings must remain visibly degraded

Current investigation note:

- one critical memory blow-up in batch trace resume logic has been identified and fixed
- targeted investigation runs can now enable `WOLFCV_MEMORY_TRACE=1`

## Read First

Read in this order:

1. [docs/table/WOLFCV_MACHINE_ONBOARDING_v0.md](docs/table/WOLFCV_MACHINE_ONBOARDING_v0.md)
2. [docs/table/APP_SPEC.md](docs/table/APP_SPEC.md)
3. [docs/table/MVP_PIPELINE.md](docs/table/MVP_PIPELINE.md)
4. [docs/table/CLI_AND_MODULE_LAYOUT.md](docs/table/CLI_AND_MODULE_LAYOUT.md)
5. [docs/table/INTERNAL_DATA_MODEL.md](docs/table/INTERNAL_DATA_MODEL.md)
6. [docs/table/WOLFCV_MAPP_YELLOWPRINT_v0.md](docs/table/WOLFCV_MAPP_YELLOWPRINT_v0.md)
7. [docs/table/WOLFCV_RUNTIME_AND_STAGE_CONTRACTS_v0.md](docs/table/WOLFCV_RUNTIME_AND_STAGE_CONTRACTS_v0.md)
8. [docs/table/WOLFCV_DEEPSEEK_PROVIDER_v0.md](docs/table/WOLFCV_DEEPSEEK_PROVIDER_v0.md)
9. [docs/table/WOLFCV_MULTI_MODEL_RUNTIME_v0.md](docs/table/WOLFCV_MULTI_MODEL_RUNTIME_v0.md)
10. [docs/table/WOLFCV_PROVIDER_INTEGRATION_v0.md](docs/table/WOLFCV_PROVIDER_INTEGRATION_v0.md)
11. [docs/table/IMPLEMENTATION_STATUS_v0.md](docs/table/IMPLEMENTATION_STATUS_v0.md)
12. [docs/table/WOLFCV_PRODUCTIZATION_v0.md](docs/table/WOLFCV_PRODUCTIZATION_v0.md)
13. [docs/table/WOLFCV_USER_FLOW_v0.md](docs/table/WOLFCV_USER_FLOW_v0.md)
14. [docs/table/WOLFCV_OUTPUT_SURFACES_v0.md](docs/table/WOLFCV_OUTPUT_SURFACES_v0.md)
15. [docs/table/WOLFCV_TRUST_AND_SHARING_v0.md](docs/table/WOLFCV_TRUST_AND_SHARING_v0.md)
16. [docs/table/WOLFCV_DEMO_RUN_v0.md](docs/table/WOLFCV_DEMO_RUN_v0.md)
17. [docs/table/WOLFCV_FIELD_TESTING_v0.md](docs/table/WOLFCV_FIELD_TESTING_v0.md)

Practical note:

- item `1` is the current shortest machine onboarding path
- items `2` through `5` are legacy-reference documents
- items `6` through `11` are the current machine-first layer
- items `12` through `17` are the first productization layer

## Short Formula

```text
WolfCV is a machine-operated compiler that turns repository truth into hiring-compatible form while forcing every strong phrase to remain traceable to bounded evidence.
```
