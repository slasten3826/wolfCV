# WolfCV :: Interpretation Profiles v0

## Status

Pencil document.

This document exists because `WolfCV` is reaching a point where
flat interpretation is no longer enough.

The machine can already:

- read repositories
- read vacancies
- build claims
- translate to hiring surfaces

But it still often reads with one default posture.

That is becoming too weak.

---

## 1. What this is

`WolfCV` needs a layer that changes **how the machine reads** a surface.

Not new evidence.
Not new truth.
Not new providers.

A new **interpretation posture**.

This is similar in spirit to `planGOD optics`,
but it should not be copied 1:1.

The current best working name is:

```text
interpretation profiles
```

Alternative names that still fit:

- reading profiles
- diagnostic profiles
- matching profiles
- interpretation modes

For now `interpretation profiles` is precise enough.

---

## 2. Why this layer is needed

The same artifact can be read differently depending on the target question.

Examples:

- a repo can be read as `systems architecture`
- or as `QA verification`
- or as `LLM runtime experimentation`

The same vacancy can be read as:

- a legitimate technical role
- a corporate ritual object
- a wishlist dump
- a social-player architecture role

Without explicit profiles,
the machine falls back to one flat reading.

That causes:

- weak prioritization
- generic claims
- over-respectful vacancy reading
- poor target matching

---

## 3. Why these are not exactly lenses

`planGOD` optics are domain lenses.

They reinterpret ProcessLang operators through domains like:

- psychology
- code
- sociology
- biology

`WolfCV` does not need domain metaphysics first.

It needs something narrower and more operational:

- how to read repo signal
- how to read vacancy bullshit
- how to rank claims for a role
- how to distinguish real fit from ritual mismatch

So these are not “knowledge lenses” in the old sense.

They are closer to:

```text
task-specific interpretation profiles
```

---

## 4. Where profiles should apply

Profiles do not need to touch every stage at once.

The most important first targets are:

- `parse_vacancy`
- `build_claims`
- `translate`

Possible later targets:

- `classify`
- `guard`

The first product value will come from better reading and matching,
not from global philosophical purity.

---

## 5. What a profile should influence

An interpretation profile may affect:

- emphasis
- ranking
- suspicion
- wording restraint
- red-flag sensitivity
- claim grouping
- target-fit diagnosis

It should **not** override raw evidence.

So a profile may influence:

```text
what is foregrounded
what is treated with suspicion
what is treated as central
```

But it must not fabricate support.

---

## 6. First likely profiles

These are the first profiles that seem genuinely useful.

### `repo_truth`

Purpose:

- read repo surfaces as evidence-bearing bodies
- prioritize supported substance over impressive vocabulary

Useful for:

- `build_claims`
- `translate`

---

### `hiring_ritual`

Purpose:

- read vacancies as ritual objects, not only as sincere technical descriptions
- detect fluff, status language, vagueness, and hidden coordination load

Useful for:

- `parse_vacancy`

---

### `llm_systems`

Purpose:

- foreground agent/runtime/orchestration/fine-tuning/inference signal
- distinguish genuine machine-systems work from shallow LLM keyword use

Useful for:

- `build_claims`
- `translate`
- `parse_vacancy`

---

### `qa_verification`

Purpose:

- foreground verification thinking
- scenario testing
- invariant checking
- smoke/bench/headless surfaces

Useful for:

- `build_claims`
- `translate`

---

### `wishlist_dump`

Purpose:

- detect roles that collapse many adjacent jobs into one
- detect incoherent seniority-to-breadth mismatch
- reduce the machine’s respect for impossible JD bundles

Useful for:

- `parse_vacancy`

---

### `architect_social_player`

Purpose:

- detect roles where the real demand is cross-team legitimacy, coordination, and technical politics
- distinguish these from hands-on builder roles

Useful for:

- `parse_vacancy`

---

## 7. First format idea

Profiles should stay simple.

A possible Lua shape:

```lua
local profile = {}

profile.name = "wishlist_dump"
profile.scope = { "parse_vacancy" }
profile.description = "Detect incoherent overpacked role definitions."

profile.hints = {
  archetype_bias = "generic_ai_wishlist",
  suspicion_bias = "high",
  prioritize_patterns = {
    "breadth_overload",
    "seniority_mismatch",
    "wish_list_dump"
  },
  wording_bias = "dry_diagnostic"
}

return profile
```

Important:

- these are hints, not hard truth replacements
- Lua may route profiles
- provider may see profile hints in prompt construction

---

## 8. Relationship to provider prompts

Profiles should not be giant prompt dumps.

That would recreate the same chaos in a new form.

Instead they should contribute bounded influence:

- prompt hints
- ranking hints
- red-flag sensitivity
- archetype bias
- wording posture

This means:

```text
profile != another freeform prompt
profile = structured interpretation modifier
```

---

## 9. Relationship to truth

Profiles are not allowed to violate truth law.

They may:

- highlight some supported signals more strongly
- read some vacancy patterns more skeptically
- choose a better target-facing arrangement

They may not:

- invent evidence
- upgrade weak claims into strong claims
- suppress uncomfortable guard results

So the law is:

```text
profiles shape reading,
not reality
```

---

## 10. First implementation posture

Do not build a huge profile system yet.

The first implementation should probably be:

1. document the profile concept
2. define 3-5 profiles
3. wire one stage to accept one profile hint
4. compare outputs before and after

This keeps the project empirical.

---

## 11. Short formula

```text
WolfCV needs a way to change how it reads,
without changing what is true.
```
