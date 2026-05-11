# WolfCV :: Runtime And Stage Contracts v0

## Status

Working canonical draft.

This document defines the first practical runtime architecture for `WolfCV`
as a machine app.

It does not define product vision in the abstract.
It defines:

- how the machine is invoked
- how stages are represented
- where Lua owns the process
- where the provider owns the cognition

---

## 1. Core split

`WolfCV` has three layers:

### Substrate

Owned by Lua.

Responsibilities:

- filesystem access
- config loading
- CLI entrypoints
- JSON persistence
- schema validation
- trace storage
- markdown writing

### Runtime

Owned by machine provider.

Responsibilities:

- artifact interpretation
- evidence synthesis
- claim formation
- vacancy reading
- wording generation
- guard judgment

### Kernel

Owned by Lua.

Responsibilities:

- stage routing
- prompt construction
- provider invocation
- parse and validate
- retry on malformed output
- forbid illegal final surfaces

Short formula:

```text
Lua owns structure
provider owns cognition
```

---

## 2. Provider boundary

The first provider is:

- `DeepSeek`

But stage logic must not know this directly.

Required provider contract:

```lua
provider.complete({
  system = "...",
  user = "...",
  temperature = 0.2,
  max_tokens = 4000,
  response_format = "json"
})
-> {
  ok = true|false,
  model = "...",
  content = "...",
  raw = {...},
  error = nil|"..."
}
```

The provider layer should be replaceable.

Current target files:

- `runtime/provider.lua`
- `runtime/deepseek.lua`

---

## 3. Stage object

Every machine stage should be represented explicitly.

Minimum shape:

```lua
{
  name = "extract_evidence",
  version = "v0",
  input_schema = "artifact_batch",
  output_schema = "evidence_batch",
  build_system_prompt = function(ctx) ... end,
  build_user_prompt = function(ctx) ... end,
  parse_output = function(text) ... end,
  validate_output = function(obj) ... end,
}
```

This means stage logic is inspectable.

It should not be hidden inside random helper code.

---

## 4. Stage runner

Canonical execution unit:

```text
StageRunner.run(stage, input_packet, runtime_config)
```

The stage runner must:

1. prepare normalized stage input
2. build prompts
3. call provider
4. persist raw response
5. parse structured output
6. validate against schema
7. retry or repair if invalid
8. persist accepted output
9. return structured packet

If schema validation fails repeatedly,
the stage must hard fail.

Do not silently continue.

---

## 5. Trace persistence

Each stage run must write a trace directory.

Recommended shape:

```text
out/
  traces/
    001_scan/
      input.json
      output.json
    002_classify/
      input.json
      system_prompt.txt
      user_prompt.txt
      raw_response.txt
      parsed_output.json
      validation.json
    003_extract_evidence/
      ...
```

This is not optional decoration.
It is part of the machine substrate.

---

## 6. Stage input packets

Each stage should receive a compact packet,
not the whole world dump blindly.

Examples:

### `classify`

Input:

- repository metadata
- selected artifact batch
- local path summaries

### `extract_evidence`

Input:

- classified artifacts
- source text slices
- repository context

### `build_claims`

Input:

- evidence batch
- optional candidate notes
- forbidden claim list

### `translate`

Input:

- claims
- vacancy map
- target mode

### `guard`

Input:

- claims
- evidence
- generated draft
- forbidden claims

Machine stages should not infer missing world context by accident.

Their packet must be deliberate.

---

## 7. Schema discipline

Structured output is mandatory.

Every machine stage must target one declared schema.

Early schema set:

- `repository_index`
- `artifact_batch`
- `evidence_batch`
- `claim_batch`
- `vacancy_map`
- `cv_draft`
- `guard_result_batch`
- `gap_batch`

Validation should be done in Lua,
not outsourced back to the model.

The model may help repair,
but Lua decides whether the result is structurally acceptable.

---

## 8. Cheap vs heavy stages

Not every stage needs equal machine involvement.

### Mostly-substrate stages

- `scan`
- path filtering
- file inventory
- extension/language guess
- output writing

### Machine-heavy stages

- `classify`
- `extract_evidence`
- `build_claims`
- `parse_vacancy`
- `translate`
- `guard`
- `gap`

This distinction matters for cost,
speed,
and architecture cleanliness.

---

## 9. Retry model

The runtime should support at least two failure classes:

### Parse failure

Machine output is malformed or not parseable.

Response:

- retry with stricter repair prompt

### Schema failure

Machine output parses,
but required fields or enums are invalid.

Response:

- run schema-repair pass once
- if still invalid, fail hard

Do not allow endless retries.

Suggested initial policy:

- `max_attempts = 2`
- `1 initial + 1 repair`

---

## 10. Hard guardrails

The machine may propose.
Lua must still block.

Hard guardrails should include:

- no final claim without evidence link
- no `FORBIDDEN` claim in final CV
- no scope escalation from `prototype` to `production`
- no missing required fields in stage output
- no final markdown generation from unguarded claims

This is the minimum falsification boundary.

---

## 11. Minimal first runtime path

The first working runtime path should be:

```text
scan
-> classify
-> extract_evidence
-> build_claims
-> parse_vacancy
-> translate
-> guard
```

`run` is then only orchestration over this chain.

Do not start with:

- rich legacy simulation
- advanced gap planning
- public profile crawling
- smart chronology synthesis

---

## 12. Short formula

```text
WolfCV runtime = provider cognition under Lua-owned stage contracts,
with schemas, traces, and hard falsification boundaries.
```
