# WOLFCV Vacancy-Aware Evidence Selection v0

## Status

Draft architecture note.

This document records a product-performance shift discovered after the
`processcards + QA vacancy` long run.

Current `WolfCV` reads too much repository material too deeply before the
vacancy has real influence on evidence cost.

That is truth-preserving, but too slow and too expensive for product use.

---

## Problem

Current truth flow is effectively:

1. scan repositories
2. classify artifacts
3. extract evidence from almost all normal artifacts
4. build claims
5. read vacancy
6. translate and guard

This means the expensive deep-reading stage happens before vacancy-aware
selection.

Observed consequence:

- one repo (`processcards`) produced `100+` evidence batches in the old mode
- full-profile preflight remained too large even after `--no-docs`
- many batches were likely redundant for the actual target vacancy

The machine was reading for generic truth coverage, not target-aware
relevance.

---

## New Direction

`WolfCV` should become vacancy-aware earlier.

The expensive deep extraction pass should happen only after a cheaper
selection pass decides which batches are worth reading for the target role.

The intended flow becomes:

1. `Lua scan`
2. `Lua batch planner`
3. `LLM vacancy-aware batch selector`
4. `LLM deep evidence extraction on selected batches only`
5. `claim building`
6. `translation and guard`

---

## Desired Pipeline

### 1. Lua Scan

Collect raw repository artifacts as today.

Responsibilities:

- enumerate files
- assign initial classes
- attach local metadata

This remains cheap and deterministic.

### 2. Lua Batch Planner

Build an intermediate reading plan before expensive evidence extraction.

Responsibilities:

- group artifacts into candidate batches
- compute batch-level signal hints
- rank batches by likely value
- suppress obvious redundancy
- keep counts, costs, and coverage hints visible

The planner does not try to understand the vacancy.
It prepares the candidate reading space.

### 3. LLM Vacancy-Aware Batch Selector

This is the critical new step.

Input:

- parsed vacancy
- batch summaries from the planner
- signal hints, class hints, repo names, and representative paths

Output:

- `read_now`
- `read_if_needed`
- `skip`

The selector does not do full evidence extraction yet.
It only decides which planned batches are worth deep reading for the current
target.

This moves vacancy influence earlier in the pipeline.

### 4. LLM Deep Evidence Extraction

Only selected batches go through the expensive `extract_evidence` stage.

This preserves the current truth discipline but applies it to a much smaller,
better-targeted set.

---

## Why This Is Better

### It preserves the law

The system still does not invent unsupported claims.
It simply avoids deep-reading material that is not relevant enough for the
current target.

### It improves economics

Fewer deep extraction batches means:

- lower latency
- lower token cost
- less prompt waste
- less repo-internal overreading

### It reduces semantic overfitting

The old mode let the machine spend too much attention on project internals.

Vacancy-aware selection should make it more likely that the machine reads:

- verification surfaces
- CLI tooling
- scenario frameworks
- invariant checking

instead of:

- local lore
- implementation trivia
- redundant explanation files

### It creates a real stop-go control point

The user can inspect:

- how many candidate batches exist
- how many were selected
- what was skipped
- why the machine believed some batches were low-value

This is productively transparent.

---

## Separation Of Roles

### Lua

Lua should control:

- batching
- ranking
- clustering
- redundancy suppression
- progress accounting
- stop/go orchestration

### LLM

The model should control:

- vacancy interpretation
- relevance judgment over candidate batches
- deep evidence extraction from selected batches

This preserves the current `WolfCV` design principle:

- machine thinks
- Lua controls topology and economics

---

## Candidate Planner Outputs

The batch planner should likely emit something like:

- `batch_id`
- `repo_id`
- `artifact_ids`
- `artifact_count`
- `class_mix`
- `signal_tags`
- `representative_paths`
- `estimated_chars`
- `estimated_cost_weight`
- `cluster_id`
- `planner_priority`
- `redundancy_flags`

This is not deep evidence.
It is a reading plan.

---

## Candidate Selector Outputs

The vacancy-aware selector should likely emit something like:

- `batch_id`
- `decision`
  - `read_now`
  - `read_if_needed`
  - `skip`
- `reason`
- `target_surface`
- `confidence`

Optional:

- `priority_rank`
- `coverage_gap_addressed`

---

## Product Implications

This architecture supports future runtime modes naturally.

### Full

- broad planner coverage
- broader selector acceptance
- deeper extraction

### Balanced

- planner suppression on
- selector reads only strong relevance batches

### Fast

- stronger planner pruning
- only top-selected batches get deep extraction

### Vacancy Only

- selector path without repo deep read

### Truth Only

- planner + deep extraction without vacancy-aware selection

---

## Immediate Practical Goal

Do not implement the whole architecture at once.

Phase it:

1. add batch planner outputs
2. add vacancy-aware selector stage
3. restrict `extract_evidence` to selected batches
4. compare:
   - latency
   - token usage
   - claim quality
   - output stability

---

## Core Law

Not everything that can be read deeply should be read deeply.

`WolfCV` should preserve truth while becoming selective earlier.

That is the point of vacancy-aware evidence selection.
