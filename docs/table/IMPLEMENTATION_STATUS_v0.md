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
- OpenAI-compatible provider bridge
- stage runner
- report writers
- schema validators
- GitHub profile ingestion helper

Current live machine stages:

- `scan`
- `classify`
- `extract_evidence`
- `build_claims`
- `parse_vacancy`
- `translate`
- `guard`

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

Current live full path:

```text
scan
-> classify
-> extract_evidence
-> build_claims
-> parse_vacancy
-> translate
-> guard
-> wolfcv
```

Confirmed successful vacancy-aware runs:

- isolated vacancy-layer run over existing `truth13` outputs
- full `run` command on a small local repo surface
- provider: `DeepSeek`
- model: `deepseek-v4-flash`
- vacancy-aware outputs written:
  - `vacancy_map.json`
  - `cv_draft.json`
  - `wolfcv_draft.md`
  - `guard_results.json`
  - `evidence_guard_report.md`
  - `wolfcv.md`

Confirmed successful GitHub source runs:

- `scan` over `--github-profile slasten3826 --include wolfcv`
- `classify` over `--github-profile slasten3826 --include wolfcv`
- repository metadata correctly records:
  - `source_type: github`
  - `owner`
  - `remote_url`
  - local cache clone path

---

## 2. Current command surface

Real commands now:

```bash
lua main.lua scan --repos ...
lua main.lua scan --github-profile slasten3826
lua main.lua classify --repos ...
lua main.lua classify --github-profile slasten3826
lua main.lua truth --repos ... --out ./wolfcv-out
lua main.lua parse-vacancy --target ./vacancy.txt --out ./wolfcv-out
lua main.lua translate --repos ... --target ./vacancy.txt --out ./wolfcv-out
lua main.lua guard --repos ... --target ./vacancy.txt --out ./wolfcv-out
lua main.lua run --repos ... --target ./vacancy.txt --out ./wolfcv-out
```

Current note:

- `truth` remains the truth-only path
- `run` is now the full vacancy-aware path
- `scan` and `classify` can now source repos from public GitHub profiles through local cache clones

---

## 3. Current outputs

Truth path currently writes:

- `repository_index.json`
- `artifacts.json`
- `classified_artifacts.json`
- `evidence_map.json`
- `claims.json`
- `machinecv.md`
- `vacancy_map.json`
- `cv_draft.json`
- `wolfcv_draft.md`
- `guard_results.json`
- `evidence_guard_report.md`
- `wolfcv.md`
- per-stage traces under `out/traces/`

GitHub source ingestion currently adds:

- profile repo enumeration through GitHub REST API
- local cache clones under `WOLFCV_GITHUB_CACHE` or `/tmp/wolfcv-github-cache`
- optional name filtering through existing `--include` and `--exclude`

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

Current runtime extension:

- stage-specific provider and model routing exists
- traces now persist `runtime.json` per stage
- `parse_vacancy` can request explicit JSON mode
- `openai_compat` can route selected stages into local or third-party OpenAI-compatible endpoints

Current operational laws:

- stages must return structured JSON
- Lua validates schema
- truncation is treated as failure
- large stage inputs are batched in Lua before provider invocation
- obvious `DOCS`, `INDEX`, `CONFIG`, and `TEST` artifacts may bypass machine classify and stay on a Lua fast-path
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
- the same runtime shape was sufficient to complete the first vacancy-aware contour on smaller repo surfaces and on top of existing `truth13` outputs
- GitHub-profile runs improved materially once classify stopped sending obvious markdown/config/test surfaces through the model

---

## 6. Current pressure points

The current main issues are not conceptual.
They are operational.

Current pressure points:

- long runs are slow on `deepseek-v4-flash`
- multi-batch `extract_evidence` is still the heaviest truth-stage pressure point
- full `run` on the complete local `WolfCV` repository remains slow and still needs one fresh confirmed completion after the vacancy-layer rollout
- guard currently depends on strict batch-scoped draft slicing to keep `flash` inside budget
- larger GitHub-profile runs are now bottlenecked more by evidence extraction than by classify

Recent improvement:

- reducing excerpt size and enforcing one-evidence-per-artifact moved the truth run materially further before truncation pressure reappeared
- adaptive batch splitting and evidence repair completed the first full truth run

---

## 7. What is not live yet

Not implemented yet:

- `legacy-test`
- `gap`
- explicit second-pass repair prompting
- richer report formatting
- stronger line-precise `source_spans`
- GitHub-native truth verification on larger multi-repo profile sets

---

## 8. Next correct moves

The next correct moves are:

1. verify `truth` on larger and messier real repo sets
2. verify fresh full `run` completion on the complete local `WolfCV` repository after the vacancy-layer rollout
3. reduce latency and failure surface in evidence / claim stages
4. verify `truth` and `run` on real multi-repo GitHub profile sets
5. harden `translate` and `guard` against broader provider drift
6. implement `gap`

This order matters.

Without a stable truth layer,
the rest becomes ritual text generation.
