# WolfCV Quickstart

This is the shortest way to use `WolfCV` for the first time.

Use this if you:

- have repositories
- have one vacancy text
- want to see whether `WolfCV` can translate your repo truth into hiring-readable form

## 1. What you need

- local repos or a public GitHub profile
- one vacancy text file
- working model provider setup

Current default:

- `DeepSeek flash`

## 2. Fast path

### Preflight first

Before a heavy run, ask `WolfCV` how many artifacts and batches it expects:

```bash
lua main.lua preflight \
  --repos ./repo1 ./repo2 \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

This writes `preflight.json` and stops before any long model stages.

### Vacancy-aware selection before deep read

If you want `WolfCV` to stop after planning and vacancy-aware batch selection:

```bash
lua main.lua select-batches \
  --repos ./repo1 ./repo2 \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

This writes:

- `batch_plan.json`
- `batch_selection.json`
- `batch_selection.md`

and stops before deep evidence extraction.

### Local repos

```bash
lua main.lua run \
  --repos ./repo1 ./repo2 \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

### GitHub profile

```bash
lua main.lua run \
  --github-profile <profile> \
  --include <repo-name> \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

### Heavy repo, lighter truth pass

If a repo has a lot of internal docs, you can skip most `DOCS` artifacts but still keep `README*`:

```bash
lua main.lua run \
  --repos ./repo1 ./repo2 \
  --target ./vacancy.txt \
  --no-docs \
  --out ./wolfcv-out
```

### Reproducible demo

```bash
lua main.lua run \
  --github-profile slasten3826 \
  --include wolfcv \
  --target ./examples/vacancies/x5_agents.txt \
  --out ./wolfcv-demo-out
```

## 3. Read these files first

1. `START_HERE.md`
2. `vacancy_diagnosis.md`
3. `machinecv.md`
4. `hhcv.md`
5. `wolfcv.md`
6. `evidence_guard_report.md`

## 4. What these files mean

- `vacancy_diagnosis.md`
  - what the vacancy seems to really ask for
- `machinecv.md`
  - what the machine believes is supported by repo evidence
- `hhcv.md`
  - hh.ru-compatible projection without fake employment history
- `wolfcv.md`
  - the vacancy-aware projection
- `evidence_guard_report.md`
  - where the system distrusted wording or support
- `START_HERE.md`
  - first summary of the whole run and what to inspect next

## 5. What quality states mean

### `solid`

The machine thinks the reading is coherent enough to trust as a normal result.

### `partial`

The reading is usable,
but some important parts are weak or incomplete.

### `degraded`

The machine did not read the target cleanly enough.
Treat the output as a weak diagnostic artifact, not as a serious final result.

## 6. What failure usually means

### Vacancy degraded

- the vacancy text was too noisy
- the model returned weak structure
- the diagnosis is not strong enough yet

### Weak `machinecv`

- the repo signal is weak
- the repo is too noisy
- the artifacts do not support strong claims

### Weak `wolfcv`

- the target vacancy and repo truth do not align well
- the translation is being constrained by lack of evidence

### Guard discomfort

- the system thinks some projected wording is stronger than the evidence safely allows

This is not necessarily a bug.
It is often the machine being honest.

## 7. What feedback is useful

If you test `WolfCV`, useful feedback is:

- was the command flow clear?
- did you understand which files to read first?
- did the vacancy diagnosis feel right or wrong?
- did the repo truth feel fairly read?
- did the translated CV feel too weak, too weird, or too inflated?
- where did you get lost?

## 8. Deeper docs

- [HUMAN_README.md](HUMAN_README.md)
- [ALPHA_TEST_FEEDBACK.md](ALPHA_TEST_FEEDBACK.md)
- [README.md](README.md)
- [docs/table/WOLFCV_ALPHA_TEST_PROTOCOL_v0.md](docs/table/WOLFCV_ALPHA_TEST_PROTOCOL_v0.md)
- [docs/table/WOLFCV_DEMO_RUN_v0.md](docs/table/WOLFCV_DEMO_RUN_v0.md)
