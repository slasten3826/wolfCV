# WolfCV :: Implementation Status v0

## Status

Living status note.

This document is not vision.
It is not a yellowprint.
It records what is already true in the repository now.

---

## 1. Live body

`WolfCV` is no longer doc-only.

Current live substrate:

- Lua entrypoint
- CLI parser and command router
- filesystem and JSON helpers
- provider boundary
- DeepSeek provider
- stage runner
- report writers
- schema validators

Current live machine stages:

- `scan`
- `classify`
- `extract_evidence`
- `build_claims`

Current live truth path:

```text
scan
-> classify
-> extract_evidence
-> build_claims
-> machinecv
```

Confirmed successful run:

- `truth13`
- provider: `DeepSeek`
- model: `deepseek-v4-flash`
- outputs written:
  - `artifacts.json`
  - `classified_artifacts.json`
  - `evidence_map.json`
  - `claims.json`
  - `machinecv.md`
- observed counts:
  - `repositories: 1`
  - `artifacts: 31`
  - `classified_artifacts: 31`
  - `evidence: 31`
  - `claims: 31`

---

## 2. Current command surface

Real commands now:

```bash
lua main.lua scan --repos ...
lua main.lua classify --repos ...
lua main.lua truth --repos ... --out ./wolfcv-out
lua main.lua run --repos ... --out ./wolfcv-out
```

Current note:

- `run` is presently a truth-layer alias
- recruiter-facing vacancy commands are not implemented yet

---

## 3. Current outputs

Truth path currently writes:

- `repository_index.json`
- `artifacts.json`
- `classified_artifacts.json`
- `evidence_map.json`
- `claims.json`
- `machinecv.md`
- per-stage traces under `out/traces/`

Trace bodies currently include:

- `input.json`
- `system_prompt.txt`
- `user_prompt.txt`
- `provider_response.json`
- `parsed_output.json`
- `validation.json`

---

## 4. Current runtime law

The provider is real runtime.
Lua is shell, memory, and guard surface.

Current default provider:

- `DeepSeek`

Current default model:

- `deepseek-v4-flash`

Current operational laws:

- stages must return structured JSON
- Lua validates schema
- truncation is treated as failure
- large stage inputs are batched in Lua before provider invocation
- small schema omissions may be repaired by stage normalization
- `extract_evidence` currently asks for at most one strongest evidence object per artifact
- truncation-triggered batches may be split adaptively by the kernel
- provider transport is retried with explicit curl retry policy

---

## 5. Main technical discoveries so far

### 5.1 Batching is not optional

Single-pass `flash` calls truncate on moderate repository surfaces.

This means:

- batching is part of the architecture
- not a temporary convenience

### 5.2 Truth can exist before vacancy logic

`extract_evidence` and `build_claims` are already meaningful without job targeting.

This confirms a key product law:

```text
truth layer first
translation later
```

### 5.3 Provider fragility must be explicit

The runtime must survive:

- malformed JSON
- unicode escapes
- fenced JSON
- missing fields
- truncation
- slow multi-batch runs

If these cases are not handled explicitly,
`WolfCV` collapses under normal machine behavior.

Current confirmed result:

- these protections were sufficient to complete the first full `truth` contour on the local `WolfCV` repository

---

## 6. Current pressure points

The current main issues are not conceptual.
They are operational.

Current pressure points:

- long runs are slow on `deepseek-v4-flash`
- multi-batch `extract_evidence` is still the heaviest truth-stage pressure point
- larger repo sets still need verification beyond the local `WolfCV` repository
- vacancy-facing path is still absent

Recent improvement:

- reducing excerpt size and enforcing one-evidence-per-artifact moved the truth run materially further before truncation pressure reappeared
- adaptive batch splitting and evidence repair completed the first full truth run

---

## 7. What is not live yet

Not implemented yet:

- `parse_vacancy`
- `translate`
- `guard`
- `legacy-test`
- `gap`
- explicit second-pass repair prompting
- richer report formatting

---

## 8. Next correct moves

The next correct moves are:

1. verify `truth` on larger and messier real repo sets
2. reduce latency and failure surface in evidence / claim stages
3. implement `parse_vacancy`
4. implement `translate`
5. implement `guard`

This order matters.

Without a stable truth layer,
the rest becomes ritual text generation.
