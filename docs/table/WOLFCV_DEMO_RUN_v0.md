# WolfCV :: Demo Run v0

## Status

Pencil demo note.

This document defines the first canonical demo run for `WolfCV`.

It is not the best possible benchmark.
It is the first shareable one.

The key property is:

```text
another person should be able to reproduce it from public inputs
```

---

## 1. Demo goal

The demo is not meant to prove perfect candidate fit.

It is meant to prove these things:

- `WolfCV` can ingest a public repo source
- `WolfCV` can read a real vacancy
- `WolfCV` can produce the main output surfaces
- the result is inspectable rather than magical

---

## 2. Canonical demo source

Use:

- GitHub profile: `slasten3826`
- included repo: `wolfcv`

Reason:

- public
- small enough to be practical
- already pressure-tested internally
- demonstrates the machine reading its own body

This is a self-demo.
That is acceptable for the first shareable path.

---

## 3. Canonical demo vacancy

Use:

- [examples/vacancies/x5_agents.txt](../../examples/vacancies/x5_agents.txt)

Reason:

- real LLM/agent-oriented target
- not absurdly domain-mismatched
- interpretable by current vacancy diagnosis layer

It is not chosen because it is the perfect fit.
It is chosen because it is a good product demo target.

---

## 4. Canonical command

```bash
lua main.lua run \
  --github-profile slasten3826 \
  --include wolfcv \
  --target ./examples/vacancies/x5_agents.txt \
  --out ./wolfcv-demo-out
```

---

## 5. Expected outputs

The demo should produce at least:

- `vacancy_diagnosis.md`
- `machinecv.md`
- `wolfcv.md`
- `evidence_guard_report.md`

Plus machine residue:

- `artifacts.json`
- `classified_artifacts.json`
- `evidence_map.json`
- `claims.json`
- `vacancy_map.json`
- `guard_results.json`
- traces

---

## 6. Reading order

First read:

1. `vacancy_diagnosis.md`
2. `machinecv.md`
3. `wolfcv.md`
4. `evidence_guard_report.md`

That order should remain the canonical demo reading order for now.

---

## 7. What the demo is proving

The demo proves:

- the app can run
- the app can read public source
- the app can read a real vacancy
- the app can produce a truth surface
- the app can produce a translated surface
- the app can expose distrust rather than hiding it

The demo does **not** prove:

- perfect fit quality
- polished end-user UX
- universal vacancy interpretation quality
- stable operation on all larger repo sets

---

## 8. Future better demos

Later there should be stronger demo classes:

- `repo truth demo`
- `strong candidate fit demo`
- `mismatch / gap demo`
- `profile-scale GitHub demo`

But right now one reproducible public run is more valuable than many hypothetical demos.

---

## 9. Short formula

```text
The first demo is not the final benchmark.
It is the first public proof that the machine is real.
```
