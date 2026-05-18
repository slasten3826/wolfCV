# WolfCV :: Multi-Model Runtime v0

## Status

Working runtime note.

This document fixes the first multi-model posture for `WolfCV`.

It is not a grand abstraction manifesto.
It records the practical law now emerging in the codebase:

```text
different stages may need different cognition bodies
```

---

## 1. Why multi-model exists

`WolfCV` does not use models for one generic chat task.

It uses them for different stage families:

- low-cost structured classification
- evidence extraction across many batches
- claim synthesis
- vacancy interpretation
- wording projection
- guard judgment

These tasks do not have the same pressure profile.

Examples:

- `classify` benefits from cheap, fast, disciplined JSON output
- `extract_evidence` benefits from low-cost repeated batch execution
- `parse_vacancy` benefits from better abstraction and role diagnosis
- `translate` and `guard` may benefit from stronger wording discipline

Interpreter note:

- `parse_vacancy` should not look successful merely because Lua backfilled empty fields
- stronger models may help abstraction, but the kernel must still expose degraded readings honestly

So the runtime law becomes:

```text
one pipeline
many cognition bodies
```

---

## 2. Core law

`WolfCV` must not be hard-bound to one provider or one model.

Instead:

- Lua owns stage routing
- Lua decides which runtime to use per stage
- traces must record which runtime actually executed a stage

Short formula:

```text
model choice is stage configuration
not stage ontology
```

This means:

- `parse_vacancy` may run on a stronger reasoning model
- `classify` may stay on a cheaper batch-friendly model
- local models may coexist with hosted APIs

without changing stage semantics.

---

## 3. Current routing posture

Current stage routing is environment-driven.

Global fallback:

```text
WOLFCV_PROVIDER
WOLFCV_MODEL
WOLFCV_BASE_URL
WOLFCV_API_KEY
WOLFCV_TEMPERATURE
WOLFCV_MAX_TOKENS
```

Stage-specific override:

```text
WOLFCV_<STAGE>_PROVIDER
WOLFCV_<STAGE>_MODEL
WOLFCV_<STAGE>_BASE_URL
WOLFCV_<STAGE>_API_KEY
WOLFCV_<STAGE>_TEMPERATURE
WOLFCV_<STAGE>_MAX_TOKENS
```

Examples:

```text
WOLFCV_PARSE_VACANCY_PROVIDER
WOLFCV_PARSE_VACANCY_MODEL

WOLFCV_TRANSLATE_PROVIDER
WOLFCV_TRANSLATE_MODEL

WOLFCV_GUARD_PROVIDER
WOLFCV_GUARD_MODEL
```

Batch descendants inherit by stage root.

Meaning:

- `extract_evidence_batch_01`
- `extract_evidence_batch_01_a`
- `extract_evidence_batch_01_b`

all resolve through:

```text
WOLFCV_EXTRACT_EVIDENCE_*
```

---

## 4. Current provider bodies

Current known runtime bodies:

- `deepseek`
- `openai_compat`

### `deepseek`

Use when:

- cheap repeated calls matter
- JSON discipline is acceptable
- batching pressure is expected

### `openai_compat`

Use when:

- a local server exposes an OpenAI-compatible `/chat/completions` endpoint
- a hosted provider exposes the same shape
- we want to route one stage to another model family without rewriting stage code

This is the bridge for:

- local models
- Claude-compatible gateways if wrapped
- Grok-compatible gateways if wrapped
- custom internal inference services

---

## 5. Runtime trace law

Every machine stage trace must persist runtime identity.

Current required trace file:

```text
runtime.json
```

This should at least record:

- provider
- model
- base_url when relevant
- temperature
- max_tokens

This matters because once `WolfCV` becomes multi-model,
we must be able to answer:

- which model produced this evidence?
- which model interpreted this vacancy?
- which model wrote this recruiter-facing draft?

Without this,
multi-model runtime becomes unauditable.

---

## 6. Design consequences

Multi-model runtime changes how stages should be thought about.

### `classify`

Should prefer:

- cheap
- fast
- stable JSON

### `extract_evidence`

Should prefer:

- low-cost repeated batch execution
- predictable structured outputs
- tolerance for heavy kernel batching

### `build_claims`

May use:

- same cheap model as evidence
- or a slightly stronger one if synthesis quality matters more than cost

### `parse_vacancy`

Should prefer:

- stronger abstraction
- better hidden-role diagnosis
- better distinction between task surface and ritual text

### `translate`

Should prefer:

- strong controlled phrasing
- safer recruiter-surface compression

### `guard`

Should prefer:

- strict support judgment
- overreach detection
- wording scrutiny

This means a practical future profile may look like:

```text
truth stages -> cheap fast model
vacancy / translate / guard -> stronger model
```

Current practical note:

- `flash` is the current operational vacancy interpreter body
- stronger `pro`-style reasoning still needs a smaller diagnosis contour before it becomes stable enough for routine vacancy work

---

## 7. Failure modes

Multi-model runtime introduces new failure classes:

- one provider hangs while another works
- one model over-reasons and burns token budget
- one provider truncates even when another would not
- local inference works but hosted inference does not
- one model returns better abstractions but worse schema discipline

Current real discovery:

- `deepseek-v4-pro` is alive
- but on longer prompts it may spend too much budget on reasoning and fail with `finish_reason=length`
- JSON mode helps on short outputs
- longer vacancy interpretation still needs prompt slimming

This is exactly why model routing belongs in runtime law,
not in ad-hoc shell commands.

---

## 8. Future direction

Multi-model runtime should later support:

- named runtime profiles such as `cheap`, `balanced`, `interpretive`
- fallback chains
- provider capability flags
- stronger stage-specific prompt variants
- smarter routing based on task family

But v0 should remain simple:

- explicit per-stage provider/model selection
- provider-neutral stage semantics
- auditable traces

That is enough to keep the architecture clean while the system grows.
