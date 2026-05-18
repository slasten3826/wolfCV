# WolfCV :: Memory Investigation v0

## Status

Active debugging document.

This document exists because `WolfCV` produced a severe memory blow-up during `processcards` runs.

This is not normal slowdown.
This is a product-stopping bug.

---

## 1. Problem statement

Observed behavior:

- `lua main.lua run --repos /home/slasten/dev/processcards ...`
- `lua main.lua classify --repos /home/slasten/dev/processcards ...`

Both processes grew into multi-gigabyte RSS.

Observed scale:

- one `run` process reached roughly `12+ GB RSS`
- one `classify` process reached roughly `10+ GB RSS`

This was enough to cause:

- swap pressure
- desktop lag
- OOM kill
- a user-visible freeze

This is a release-blocking issue.

---

## 2. What is known already

- the freeze was not a `Wayland` issue in this case
- the immediate trigger was `WolfCV` Lua processes consuming too much memory
- the problem appeared while testing `processcards`
- `scan` completed and wrote:
  - `repository_index.json`
  - `artifacts.json`
  - `scan_summary.txt`
- the memory explosion happened after that, inside the truth path

Important distinction:

- this is not yet proven to be a classic memory leak
- it is at least a severe memory blow-up / unbounded retention bug

---

## 3. First hypotheses

Potential fault zones:

- `run_classify`
- batch preparation before `stage_runner`
- prompt serialization
- JSON pretty encoding
- large table retention across stage boundaries
- repeated duplication of arrays or strings

---

## 4. First confirmed root cause

The first confirmed blow-up was not provider latency
and not model output size.

It was an infinite recursion in batch trace resume logic:

- function: `load_batch_trace_result`
- file: `core/pipeline.lua`

Failure mode:

- when no trace existed for `batch_01`
- the function tried `batch_01_a`
- then `batch_01_a_a`
- then `batch_01_a_a_a`
- and so on forever

This produced:

- unbounded recursive calls
- memory growth
- swap pressure
- eventual OOM

The bug appeared before normal classify traces were written,
which is why the run looked like a mysterious freeze after `scan`.

Fix:

- only recurse into `_a` / `_b` trace branches if those directories actually exist

Result after fix:

- `processcards` classify no longer jumped into multi-gigabyte RSS
- memory trace stayed around a few MB of Lua heap and a few MB of RSS
- classify advanced into normal batch traces
- a full `run` advanced deep into `extract_evidence` without reintroducing the old blow-up

---

## 5. Debug stand result

With:

```bash
WOLFCV_MEMORY_TRACE=1 lua main.lua classify \
  --repos /home/slasten/dev/processcards \
  --out /tmp/wolfcv-processcards-classify-debug2
```

Observed after fix:

- `run_scan` completed normally
- `run_classify` advanced into `batch_01`, `batch_02`, `batch_03`
- `memory_trace.log` showed stable memory
- no immediate blow-up

Deeper confirmation:

- full `run` reached well beyond `extract_evidence_batch_30`
- RSS stayed small instead of exploding into GB
- no new OOM pattern appeared in the same reproduction contour

This confirms the main freeze cause was the recursive resume bug.

---

## 6. Test stand

Primary reproduction target:

```bash
lua main.lua classify \
  --repos /home/slasten/dev/processcards \
  --out /tmp/wolfcv-processcards-classify-debug
```

Secondary reproduction target:

```bash
lua main.lua run \
  --repos /home/slasten/dev/processcards \
  --target /tmp/wolfcv-qa-game-vacancy.txt \
  --out /tmp/wolfcv-processcards-run-debug
```

Debug mode:

```bash
WOLFCV_MEMORY_TRACE=1 lua main.lua classify \
  --repos /home/slasten/dev/processcards \
  --out /tmp/wolfcv-processcards-classify-debug
```

This should produce:

- normal output artifacts
- `memory_trace.log`

---

## 7. Investigation law

Do not guess from symptoms only.

For each suspected stage:

1. reproduce
2. capture memory trace
3. localize spike
4. patch
5. re-run the same reproduction target

---

## 8. Success condition

The bug is considered fixed when:

- the same `processcards` test no longer grows into multi-gigabyte RSS
- the run completes or fails honestly without system-level memory pressure
- normal product use does not threaten desktop stability

---

## 9. Short formula

```text
WolfCV is allowed to be slow.
WolfCV is not allowed to eat the machine.
```
