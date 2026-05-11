# WolfCV :: MAPP YELLOWPRINT v0

## Status

Working yellowprint.

This is not final implementation law.
This is not a complete spec.
This document fixes the first honest shape of `WolfCV`
after the shift from:

```text
CLI utility with some AI help
```

to:

```text
mapp
```

Meaning:

- machine app
- machine runtime is the thinking body
- Lua code is the substrate, routing shell, and guard surface
- the product is built for machine execution first
- human-readable CV output is a late manifestation layer

---

## 1. Core thesis

`WolfCV` should not be built as:

- a deterministic résumé formatter
- a template filler
- a keyword spamming tool
- a Python rules engine with summary prompts on top

`WolfCV` should be built as:

```text
machine-operated evidence-to-CV compiler
```

More precisely:

```text
source repos + target vacancy
-> machine runtime
-> structured truth packets
-> guarded hiring manifestation
```

Short formula:

```text
machine thinks
lua routes, validates, persists, forbids cheating
```

---

## 2. Product law

Canonical law remains:

```text
artifact -> evidence -> claim -> translation -> validation -> gap
```

But after the `mapp` shift,
this chain should now be read as:

```text
machine stage outputs
under explicit schema and guard law
```

Not:

```text
free-form prose at each step
```

If a stage cannot return structured data,
that stage is not finished.

---

## 3. Runtime posture

`WolfCV` is machine-first.

The primary execution body is:

- external LLM runtime over API

The first chosen runtime is:

- `DeepSeek`

The application must still keep a provider boundary,
so that future runtimes can be swapped without rewriting stage logic.

Current reading:

```text
DeepSeek = first cognition runtime
Lua = substrate and topology shell
```

---

## 4. Why Lua

First implementation is `Lua-first`.

This is not a nostalgia choice.
It is a runtime-shape choice.

Lua is preferred here because:

- it is light as orchestration glue
- it does not pretend to be the main intelligence body
- it fits machine-facing runtime shells well
- it keeps the code layer thin enough
- it matches the existing stack habits of the author

Practical reading:

```text
Lua should stay thin.
If Lua starts re-implementing the machine,
the architecture is already drifting.
```

---

## 5. Main internal machines

The internal machines remain:

- `MachineCV`
- `Wolf Adapter`
- `EvidenceGuard`
- `LegacyHR`
- `Gap Planner`

But now they should be read as:

```text
distinct machine stage contracts
```

### `MachineCV`

Truth engine.

Task:

- read source artifacts
- produce bounded evidence
- derive support-aware claims
- keep truth layer visible

### `Wolf Adapter`

Translation engine.

Task:

- take safe claims
- align them to vacancy pressure
- produce recruiter-readable wording
- not increase scope dishonestly

### `EvidenceGuard`

Boundary engine.

Task:

- judge whether a claim is safe
- detect overreach
- force safer wording
- block forbidden output

### `LegacyHR`

Shallow ritual simulator.

Task:

- estimate first-pass legibility
- identify obvious missing familiar signals
- detect “too weird too early” phrasing

### `Gap Planner`

Signal repair engine.

Task:

- identify unsupported high-pressure vacancy zones
- suggest honest bridge work

---

## 6. Machine stage model

The first `WolfCV` should be built around explicit stage contracts.

Not:

- hidden LLM calls inside random helper modules

But:

```text
StageRunner + schema + prompt contract + parse + validate + trace
```

Each machine stage must have:

- stage name
- input schema
- output schema
- system contract
- prompt builder
- parser
- validator
- retry/repair logic
- trace persistence

If one of these pieces is missing,
the stage is incomplete.

---

## 7. Canonical MVP stages

The first real machine stages should be:

### Stage 0 — `scan`

Mostly Lua.

Responsibilities:

- repo discovery
- file inventory
- extension/path metadata
- ignore/generated filtering

This stage is structural, not cognitive.

### Stage 1 — `classify`

Machine-assisted but cheap.

Responsibilities:

- classify artifacts
- assign class
- assign role tags
- keep confidence

### Stage 2 — `extract_evidence`

Heavy machine stage.

Responsibilities:

- turn artifacts into bounded evidence statements
- keep them local and factual
- attach limitations

### Stage 3 — `build_claims`

Heavy machine stage.

Responsibilities:

- group evidence
- derive recruiter-usable claims
- mark support level
- produce safer wording

### Stage 4 — `parse_vacancy`

Machine stage with structured output.

Responsibilities:

- extract keywords
- separate hard and soft requirements
- estimate ritualization pressure

### Stage 5 — `translate`

Machine stage.

Responsibilities:

- build `wolfcv.md`
- choose strongest safe framing
- preserve truth linkage

### Stage 6 — `guard`

Machine stage plus hard Lua checks.

Responsibilities:

- evaluate claims and final wording
- block unsupported or forbidden phrasing

### Stage 7 — `gap`

Optional in first pass.

Responsibilities:

- identify unsupported pressure points
- propose bridge artifacts

---

## 8. Hard law vs machine law

`WolfCV` should not be rule-only.
But it also must not be machine-anarchy.

Split the laws explicitly.

### Machine law

Machine should decide:

- what an artifact likely means
- what evidence is extractable
- what claim shape is appropriate
- how vacancy pressure should be read
- which safe wording best fits the target vacancy

### Hard Lua law

Lua must enforce:

- schema validity
- required fields exist
- evidence linkage exists
- forbidden statuses cannot leak into final CV
- support scope cannot silently disappear
- trace files persist

Short formula:

```text
meaning by machine
boundaries by code
```

---

## 9. Trace policy

Because this is a `mapp`,
the runtime residue matters.

`WolfCV` should preserve:

- stage input payload
- prompt contract
- provider name
- model name
- raw machine output
- parsed output
- validation failures
- final accepted output

Meaning:

```text
final json/md is not enough
machine residue is part of the product truth
```

This is important for:

- debugging
- reproducibility
- guard disputes
- future provider swaps

---

## 10. Persistence policy

The primary substrate remains structured files.

First-class outputs:

- `repository_index.json`
- `artifacts.json`
- `evidence_map.json`
- `claims.json`
- `vacancy_map.json`
- `guard_results.json`
- `gap_report.json`
- stage trace files

Derived manifestations:

- `machinecv.md`
- `wolfcv.md`
- `evidence_guard_report.md`
- `legacyhrcv_report.md`

Short formula:

```text
json + traces = machine substrate
markdown = manifestation
```

---

## 11. MVP proof target

The first benchmark should be a real one.

Not synthetic examples.

Canonical first proof:

- one real candidate stack
- one real LLM/ML vacancy
- one real output directory

Suggested first repo slice:

- `x12`
- `planGOD`
- `packet-slop`
- `doom2packet`
- `processcards`

The first version succeeds if it can:

1. build a believable `machinecv.md`
2. build a more legible `wolfcv.md`
3. visibly stop unsupported overreach

---

## 12. First implementation cut

Do not build the full dream first.

First implementation cut should be:

- `scan`
- `classify`
- `extract_evidence`
- `build_claims`
- `parse_vacancy`
- `translate`
- `guard`
- `run`

Delay richer versions of:

- `legacy-test`
- `gap`
- public GitHub crawling
- chronology reconstruction
- ATS mysticism

---

## 13. Short formula

```text
WolfCV mapp = repos and vacancy enter a machine runtime;
Lua keeps the runtime structured, traceable, and unable to drift into false history.
```
