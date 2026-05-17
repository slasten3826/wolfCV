# WolfCV :: Machine Onboarding v0

## Status

Working machine handoff note.

This document exists for one purpose:

```text
let a new machine understand what WolfCV is,
why it exists,
what kind of truth it protects,
and how to enter the repo without wasting context.
```

It is not a full spec.
It is the shortest honest bridge from zero context to useful action.

---

## 1. What this project is

`WolfCV` is not a normal résumé helper.

It is a machine-operated translator between:

- repository truth
- and hiring ritual form

Short formula:

```text
repo truth
-> evidence
-> claims
-> vacancy-aware translation
-> guard
-> CV surface
```

The project exists because strong technical signal often lives in:

- repositories
- specs
- experiments
- architecture
- machine-facing artifacts

while hiring systems often read only:

- job titles
- years
- keywords
- familiar commercial labels

`WolfCV` exists to reduce that mismatch
without fabricating history.

---

## 2. Why it was started

The project did not begin as an abstract startup idea.

It began from a concrete pressure:

- the candidate behind the repo has real technical depth
- much of that depth is repo-shaped rather than HR-shaped
- strong roles exist that the candidate may be able to do
- but the signal is badly translated into hiring-readable form

This matters because `WolfCV` is not trying to make weak candidates look strong.

Its real function is:

```text
detect real substance
translate it honestly
refuse unsupported inflation
show gaps when the target role is genuinely mismatched
```

This is why the project must preserve truth boundaries so aggressively.

---

## 3. What kind of candidate it is for

`WolfCV` is not designed for everyone equally.

Its natural target is a candidate who has:

- real technical substance
- artifacts that can be read by a machine
- a profile that is nonstandard or badly legible to HR
- meaningful repo evidence
- enough machine-facing work that claims can be traced

It is weak when:

- there is no substance
- there are no artifacts
- the desired role depends on domain experience that does not exist anywhere in evidence

In that case `WolfCV` should not hallucinate.
It should expose a gap.

---

## 4. What kind of vacancies it reads well

The repo has already been pressure-tested against multiple vacancy shapes:

- narrow medical CV roles
- generic LLM/NLP roles
- search + RAG hybrid roles
- CUA / agent-system roles
- architect / social-player roles
- generic AI wishlist dumps
- QA automation roles with AI tooling

This already established an important fact:

`WolfCV` does not only translate candidate truth.
It also reads vacancy shape.

So the system is becoming bidirectional:

```text
candidate truth -> hiring form
vacancy text -> real role shape
```

This is part of the core identity now.

---

## 5. Current benchmark posture

The project should be read through concrete benchmarks,
not only through abstract module descriptions.

Current meaningful benchmark classes:

### Benchmark A — truth extraction

Can the machine read a repo and produce:

- `artifacts.json`
- `classified_artifacts.json`
- `evidence_map.json`
- `claims.json`
- `machinecv.md`

without inventing unsupported experience?

### Benchmark B — vacancy interpretation

Can the machine read a vacancy and separate:

- core task surface
- hard requirements
- soft requirements
- ritual language
- hidden role shape
- red flags

### Benchmark C — role translation

Can the machine align repo truth with a specific vacancy
without inflating scope or inventing credentials?

### Benchmark D — gap exposure

When the role is genuinely mismatched,
can the system say so honestly?

This benchmark is as important as success-case generation.

---

## 6. What is already true in the codebase

The current live body already has:

- truth extraction stages
- vacancy parsing
- translation
- guard
- GitHub profile ingestion
- stage traces
- stage batching and adaptive split
- first multi-model routing posture
- provider bridge for OpenAI-compatible endpoints

This means the project is no longer mostly speculative.

The machine can already:

- read local repos
- read cached GitHub repos
- produce evidence and claims
- produce vacancy diagnosis
- produce recruiter-facing drafts on some surfaces

The remaining work is now more about:

- quality
- routing
- better interpretation
- cleaner outputs

than about proving the architecture is possible at all.

---

## 7. Main laws a new machine must preserve

If you work on this repo,
do not violate these laws:

### Law 1 — truth first

`machinecv` matters more than polished recruiter prose.

### Law 2 — translation is allowed, fabrication is not

No invented:

- employers
- dates
- deployments
- metrics
- degrees
- production claims

### Law 3 — stage outputs must stay structured

If a stage drifts into free-form text,
the architecture is decaying.

### Law 4 — traces are part of the product

They are not debug trash.
They are the audit surface.

### Law 5 — model identity matters

Once multi-model routing exists,
every stage should remain attributable to:

- provider
- model
- runtime settings

### Law 6 — vacancies also need interpretation

Do not assume vacancy text is clear or honest.
The system should read vacancy ritual critically.

---

## 8. Where a new machine should read first

Recommended entry order:

1. `README.md`
2. `docs/table/WOLFCV_MACHINE_ONBOARDING_v0.md`
3. `docs/table/WOLFCV_MAPP_YELLOWPRINT_v0.md`
4. `docs/table/WOLFCV_RUNTIME_AND_STAGE_CONTRACTS_v0.md`
5. `docs/table/WOLFCV_MULTI_MODEL_RUNTIME_v0.md`
6. `docs/table/WOLFCV_PROVIDER_INTEGRATION_v0.md`
7. `docs/table/IMPLEMENTATION_STATUS_v0.md`

Then read code.

Do not start from legacy docs unless you need genealogy.

---

## 9. How to be useful quickly

If you are a machine entering this project fresh,
the highest-value tasks are usually:

- improve vacancy interpretation
- improve claim ranking
- improve guard strictness
- improve output shaping for different audiences
- improve provider routing and reliability
- preserve or strengthen traceability

The lowest-value failure mode is:

```text
turn WolfCV into a generic CV text generator
```

That is exactly what the project exists to avoid.

---

## 10. Short conclusion

Read `WolfCV` as:

```text
a machine-operated interpreter of the hiring boundary
whose job is to make real technical signal legible
without betraying the truth that produced it
```

That is where the legs of the project come from.
