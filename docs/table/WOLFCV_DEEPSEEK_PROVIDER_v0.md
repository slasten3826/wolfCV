# WolfCV :: DeepSeek Provider v0

## Status

Working provider note.

This document fixes the first provider posture for `WolfCV`.

It is not a universal provider abstraction spec.
It is the initial practical contract for using `DeepSeek`
as the first cognition runtime.

Current implementation posture:

- default model is `deepseek-v4-flash`
- provider is already wired into live `classify`, `extract_evidence`, and `build_claims`
- current bottlenecks are truncation on long arrays and latency across many batches

---

## 1. Why DeepSeek first

`DeepSeek` is selected as the first provider because:

- it is already available on the machine
- it is good enough for rapid stage testing
- early `WolfCV` needs many cheap iterative runs
- provider stability matters more than frontier prestige at MVP stage

This choice is practical,
not theological.

`DeepSeek` is first.
It is not “the only model forever”.

Current practical model choice:

- `deepseek-v4-flash`

Reason:

- it is cheap enough for repeated stage testing
- it is good enough for structured JSON work
- it forces `WolfCV` to learn batching and discipline early

---

## 2. Role of provider

The provider is not the application.

It is the cognition runtime serving stage contracts.

Meaning:

- it interprets artifacts
- it proposes evidence
- it builds claims
- it reads vacancies
- it produces recruiter-facing drafts
- it judges support boundaries

But it does so only inside:

- explicit stage prompts
- explicit schemas
- explicit retry logic

---

## 3. First provider contract

Minimum request contract:

```lua
deepseek.complete({
  system = "...",
  user = "...",
  temperature = 0.1,
  max_tokens = 4000
})
```

Current real wrapper behavior also checks:

- missing API key
- malformed provider JSON
- truncated responses via `finish_reason == "length"`

Minimum response contract:

```lua
{
  ok = true,
  provider = "deepseek",
  model = "...",
  content = "...",
  raw = {...},
  error = nil
}
```

Failure shape:

```lua
{
  ok = false,
  provider = "deepseek",
  model = nil,
  content = nil,
  raw = {...},
  error = "..."
}
```

---

## 4. Environment posture

The API key should come from environment,
not hardcoded config.

First-pass posture:

- read API key from environment
- fail clearly if missing
- never write key into traces

Traces may contain:

- provider name
- model name
- token/runtime metadata if available

Traces must not contain:

- secret keys

Current operational note:

- sandboxed local runs may fail DNS resolution
- real provider verification may require running outside the sandbox

---

## 5. Prompt style for DeepSeek

Prompt contracts for `DeepSeek` should be:

- direct
- schema-first
- low-temperature
- low-poetry
- explicit about forbidden behavior

Avoid:

- open-ended summary prompts
- persona-heavy nonsense
- “be helpful” fluff

Prefer:

- explicit field list
- explicit enums
- explicit “do not invent”
- explicit “return only JSON”

---

## 6. Repair loop

`DeepSeek` should be assumed capable but not perfect.

So provider use must support:

- first pass for normal output
- one repair pass for malformed output
- hard failure on truncation or missing content
- batching before prompt size becomes irresponsible

Repair prompt should include:

- previous raw output
- parse/schema error summary
- same schema contract
- instruction to return corrected JSON only

Do not allow indefinite self-repair spirals.

Current implementation note:

- post-parse repair currently happens in stage-level normalization for small schema omissions
- full explicit second-pass repair prompting is not implemented yet

---

## 7. Stage suitability

Expected strong use cases for first `DeepSeek` pass:

- artifact classification
- evidence extraction
- claim synthesis
- vacancy parsing
- translation
- guard judgments

Expected weaker areas:

- nuanced chronology inference
- exact production-vs-prototype reconstruction without strong evidence
- subtle real-world hiring heuristics beyond text evidence

This means:

`DeepSeek` is suitable for MVP cognition,
but Lua still has to own guard law.

---

## 8. Provider neutrality rule

Even though `DeepSeek` is first,
stage definitions must not become `DeepSeek`-specific in their semantics.

Allowed provider-specific things:

- endpoint details
- HTTP payload shape
- auth handling
- response parsing
- finish-reason handling
- throughput and batching heuristics

Not allowed:

- embedding provider identity into stage ontology
- binding schemas to one provider’s quirks
- making trace formats provider-exclusive

---

## 9. First practical use

The first provider-backed proof should target:

- `extract_evidence`
- then `build_claims`

Reason:

these two stages are the real center of `WolfCV`.

If `DeepSeek` cannot produce useful structured evidence and claims,
the product loop is not alive yet.

Current result:

- that proof is partially achieved
- `classify` is stable after batching
- `extract_evidence` and `build_claims` now have live stage bodies
- the remaining issue is operational stability on longer multi-batch runs, not absence of product shape

---

## 10. Short formula

```text
DeepSeek is the first WolfCV cognition runtime;
Lua must keep it structured, repairable, and unable to drift into unsupported history.
```
