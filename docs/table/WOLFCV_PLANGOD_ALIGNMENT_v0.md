# WolfCV :: planGOD Alignment v0

## Status

Working comparison note.

This document exists to freeze one important realization:

```text
WolfCV and planGOD are not unrelated projects.
They are different manifestations of the same architectural instinct.
```

It does not merge them.
It only records:

- where they match
- where they diverge
- what kind of truth each one currently owns

---

## 1. Short conclusion

`planGOD` is the broader machine-runtime organism.

`WolfCV` is a narrower boundary machine built around one specific translation problem:

```text
repo truth -> hiring ritual form
```

So the right reading is not:

```text
which repo replaces which repo?
```

but:

```text
what in planGOD is general law,
and what in WolfCV is domain-specific manifestation?
```

---

## 2. Core alignment

### 2.1 Machine runtime first

Both repos treat the real thinking body as the model runtime,
not the host language.

`planGOD` says:

- the agent thinks through `ProcessLang`
- Lua routes the system
- topology prevents illegal manifestation

`WolfCV` says:

- the machine interprets artifacts and vacancies
- Lua routes, validates, persists, forbids cheating

Shared law:

```text
model = cognition
Lua = body / kernel / routing / guard
```

---

### 2.2 Architectural anti-hallucination

Both systems try to solve hallucination structurally,
not only with prompt wording.

In `planGOD`:

- there is no direct legal path from `OBSERVE` to `MANIFEST`
- topology itself blocks premature answer emission

In `WolfCV`:

- there should be no direct legal path from raw repo surface to final CV surface
- output is forced through `evidence`, `claims`, and `guard`

Shared law:

```text
manifestation must be forced through intermediate legality layers
```

---

### 2.3 Packet / stage thinking

`planGOD` uses a canonical `Packet` as a system bus.

`WolfCV` uses stage packets with:

- input packet
- prompt contract
- parsed output
- schema validation
- trace persistence

These are not identical implementations,
but they are clearly isomorphic.

Shared law:

```text
modules do not talk through hidden global soup;
they exchange bounded machine-readable packets
```

---

### 2.4 Topology as truth

`planGOD` has explicit module topology:

```text
FLOW -> CONNECT -> ENCODE -> OBSERVE -> ...
```

`WolfCV` has an emerging stage topology:

```text
scan -> classify -> extract_evidence -> build_claims -> parse_vacancy -> translate -> guard
```

Both repos assume that order matters.

Shared law:

```text
the path itself is part of the truth contract
```

---

### 2.5 Runtime residue

`planGOD` persists:

- `history`
- `E_momentum`
- `E_edges`
- runtime storage

`WolfCV` persists:

- `artifacts.json`
- `classified_artifacts.json`
- `evidence_map.json`
- `claims.json`
- `vacancy_map.json`
- traces per stage

Different forms, same instinct:

```text
a machine run should leave auditable residue,
not only final prose
```

---

## 3. Structural correspondences

These are not perfect one-to-one equivalents,
but they are close enough to matter.

### `planGOD` -> `WolfCV`

- `FLOW`
  - first intake of raw input
  - closest `WolfCV` surface: `scan` or `parse_vacancy` entry ingestion

- `CONNECT`
  - builds contextual links and loads memory
  - closest `WolfCV` surface: repo grouping, artifact context assembly, vacancy/context joining

- `ENCODE`
  - crystallizes context into prompt form
  - closest `WolfCV` surface: stage prompt builders

- `OBSERVE`
  - LLM-facing observation/planning center
  - closest `WolfCV` surface: the provider-backed interpretive stages as a class

- `LOGIC`
  - constraint enforcement and execution legality
  - closest `WolfCV` surface: schema validation, stage runner checks, guard boundaries, normalization law

- `RUNTIME`
  - persistent state and pattern inertia
  - closest `WolfCV` surface: traces, intermediate JSON artifacts, cached GitHub repo state

- `MANIFEST`
  - final bounded output
  - closest `WolfCV` surface: `machinecv.md`, `wolfcv.md`, `vacancy_diagnosis.md`

Important:

`WolfCV` does not yet have a fully explicit named topology at the same conceptual depth as `planGOD`.
But the shape is already there.

---

## 4. Main divergences

### 4.1 Breadth of purpose

`planGOD` is a general machine-thinking runtime.

It is trying to be something like:

- a cognitive daemon
- a ProcessLang organism
- a persistent analytical machine

`WolfCV` is much narrower.

It is trying to solve one boundary problem well:

```text
translate technical truth into hiring-readable form without fabrication
```

This narrower scope is not a weakness.
It is why `WolfCV` reached a practical working contour faster.

---

### 4.2 Memory philosophy

`planGOD` has a stronger explicit theory of memory:

- `E_momentum`
- `E_edges`
- decay
- pattern inertia

`WolfCV` currently has persistence,
but not yet a real theory of memory.

It stores traces and outputs,
but it does not yet really accumulate candidate-pattern inertia
across multiple runs in a principled way.

So here `planGOD` is clearly deeper.

---

### 4.3 Ontological ambition

`planGOD` has explicit metaphysical vocabulary:

- process instead of state
- operators as primitives of cognition
- topology as law

`WolfCV` currently expresses similar instincts more pragmatically:

- stage contracts
- schemas
- traces
- guard reports

This makes `WolfCV` more operational,
but less explicitly self-theorized.

---

### 4.4 Domain specialization

`WolfCV` has already evolved domain logic that `planGOD` does not have:

- evidence extraction
- claim building
- vacancy diagnosis
- recruiter-surface translation
- falsification guard for hiring claims

This is genuinely `WolfCV`'s own body.
It should not be dissolved back into genericity.

---

## 5. Truth ownership

This is the most important section.

### `planGOD` currently owns architectural truth about:

- machine runtime as organism
- packet-oriented cognition flow
- topology as anti-hallucination law
- stronger process ontology
- memory as dynamic pattern residue

### `WolfCV` currently owns domain truth about:

- repo-to-evidence compilation
- claim safety and support levels
- vacancy interpretation
- hiring-ritual translation
- CV/guard manifestation surfaces

So source-of-truth should be read in two layers:

```text
general machine architecture truth -> planGOD
domain truth for hiring translation -> WolfCV
```

This is better than pretending one repo should simply swallow the other immediately.

---

## 6. What should probably be synchronized

Not code first.
Laws first.

Most important future sync surfaces:

- stage/module topology naming
- packet contract philosophy
- runtime identity and trace law
- legality boundaries before manifestation
- provider routing posture
- memory / residue philosophy

If synchronization is done,
it should start from these architectural laws,
not from bulk code migration.

---

## 7. What should stay separate for now

`WolfCV` should keep its own domain-specialized machinery:

- evidence schemas
- claim schemas
- vacancy diagnosis structures
- CV draft and guard reports
- GitHub profile ingestion

`planGOD` should keep its broader machine-runtime ambition:

- ProcessLang operator system
- module-topology law
- inertia-based memory theory
- general analytical agent posture

Trying to flatten both into one repo immediately would probably destroy momentum.

---

## 8. Practical reading

The current best practical reading is:

```text
planGOD = architectural ancestor / broader runtime philosophy
WolfCV  = specialized manifestation machine
```

That means:

- `planGOD` should inform `WolfCV`
- `WolfCV` should pressure-test `planGOD` ideas in a concrete market boundary

This is a healthy asymmetry.

---

## 9. Next useful step

Do not merge code yet.

Instead, define a second document later if needed:

`WOLFCV_PLANGOD_SYNC_PLAN_v0.md`

That document should answer:

- which laws move first
- which names should align
- whether `WolfCV` should eventually sit on a shared kernel
- whether synchronization should stay conceptual rather than code-level

For now this document is enough:

```text
the kinship is real,
the divergence is also real,
and both should be named before any migration begins.
```
