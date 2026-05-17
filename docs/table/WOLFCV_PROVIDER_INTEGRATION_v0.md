# WolfCV :: Provider Integration v0

## Status

Working integration note.

This document exists so future people do not need to reverse-engineer
provider support from the Lua code.

It defines how to plug new cognition runtimes into `WolfCV`.

Examples we care about:

- Claude through a compatible gateway
- Grok through a compatible gateway
- local OpenAI-compatible servers
- future direct providers with their own APIs

---

## 1. Provider boundary

All machine providers sit behind:

- [runtime/provider.lua](/home/slasten/dev/WolfCV/runtime/provider.lua)

The provider registry chooses a concrete runtime body from `runtime_cfg.provider`.

Current bodies:

- `runtime/deepseek.lua`
- `runtime/openai_compat.lua`

The rest of the pipeline should not know endpoint details.

That is the provider law.

---

## 2. Required provider contract

A provider module must export:

```lua
complete(runtime_cfg, request)
```

Request shape:

```lua
{
  system = "...",
  user = "...",
  temperature = 0.1,
  max_tokens = 4000,
  response_format = { type = "json_object" } -- optional
}
```

Success shape:

```lua
{
  ok = true,
  provider = "provider_name",
  model = "actual-model-id",
  content = "...",
  raw = {...},
  error = nil
}
```

Failure shape:

```lua
{
  ok = false,
  provider = "provider_name",
  model = "requested-model-id",
  content = nil,
  raw = {...},
  error = "human-readable failure"
}
```

The stage runner depends on this exact posture.

---

## 3. Provider responsibilities

The provider module owns:

- auth handling
- endpoint URL construction
- HTTP transport
- request payload shape
- response decoding
- detection of truncation / missing content

The provider module must not own:

- stage semantics
- claim logic
- vacancy interpretation law
- schema validation
- stage retry trees

Short formula:

```text
provider owns transport and raw model response
Lua kernel owns stage truth
```

---

## 4. What a new provider must do

Minimum implementation steps:

1. Create `runtime/<provider>.lua`
2. Implement `complete(runtime_cfg, request)`
3. Return the standard success/failure shapes
4. Register it in `runtime/provider.lua`
5. Test one small `parse-vacancy` run
6. Check `runtime.json` and `provider_response.json` traces

That is enough for first integration.

---

## 5. Environment posture

Providers should read secrets from environment,
not from committed config.

Examples:

### DeepSeek

```text
DEEPSEEK_API_KEY
DEEPSEEK_KEY
```

### OpenAI-compatible

```text
OPENAI_BASE_URL
OPENAI_API_KEY
```

Or stage-scoped overrides:

```text
WOLFCV_PARSE_VACANCY_PROVIDER=openai_compat
WOLFCV_PARSE_VACANCY_BASE_URL=http://127.0.0.1:8000/v1
WOLFCV_PARSE_VACANCY_MODEL=local-pro
WOLFCV_PARSE_VACANCY_API_KEY=...
```

Providers must never write secrets into traces.

---

## 6. JSON mode and structured output

Some providers support explicit JSON mode.

`WolfCV` stage objects may request this through:

```lua
response_format = { type = "json_object" }
```

Example current use:

- `parse_vacancy`

Why this matters:

- some stronger models over-reason
- they may spend too much budget before returning actual JSON
- explicit JSON mode can reduce this failure mode

Providers should pass `response_format` through when the API supports it.

If unsupported,
the provider may ignore it,
but should do so consciously.

---

## 7. OpenAI-compatible bridge

`openai_compat` is intentionally important.

It is not just a convenience wrapper.
It is the main bridge for:

- local inference servers
- future private hosted models
- compatibility layers around Claude / Grok / others

Endpoint rule:

- if `base_url` already ends with `/chat/completions`, use it directly
- otherwise append `/chat/completions`

This keeps integration simple.

---

## 8. Provider-specific risk patterns

When integrating a provider,
always check these classes of failure:

- empty `content`
- truncation with `finish_reason=length`
- malformed JSON
- long hidden reasoning before content
- very slow first-token latency
- strict auth / rate-limit errors

Current real example:

- `deepseek-v4-pro` can answer short JSON prompts
- but on longer vacancy prompts it may burn budget on reasoning and fail to return usable content in time

This kind of discovery must shape stage routing,
not be dismissed as random flakiness.

---

## 9. Practical integration checklist

Before declaring a provider “supported”, verify:

- one tiny direct request succeeds
- one `parse-vacancy` run succeeds
- one `translate` or `guard` run succeeds
- traces contain:
  - `runtime.json`
  - `provider_response.json`
  - `parsed_output.json`
  - `validation.json`

Only then should the provider be treated as part of the live runtime set.

---

## 10. Future providers

Likely future integration paths:

- direct `anthropic`
- direct `xai`
- stronger local providers behind OpenAI-compatible gateways
- specialized judge-only models

The law should stay the same:

```text
new providers may enter the runtime
without changing stage ontology
```

That is the main architectural reason to document this layer early.
