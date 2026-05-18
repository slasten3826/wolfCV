# WolfCV

`WolfCV` helps turn repository truth into hiring-readable form without inventing fake history.

It is meant for people who have:

- real technical repositories
- a messy or nonstandard profile
- difficulty translating repo-shaped signal into normal hiring language

It is not a generic résumé writer.

It tries to do four things:

1. read repositories
2. extract supported evidence
3. read a target vacancy
4. build a guarded CV surface without pretending unsupported things are true

## What you need

- either local repos or a public GitHub profile
- one vacancy text file
- a working model provider setup

Current default runtime:

- `DeepSeek flash`

## Fast path

Local repos:

```bash
lua main.lua run \
  --repos ./repo1 ./repo2 \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

GitHub profile:

```bash
lua main.lua run \
  --github-profile <profile> \
  --include <repo-name> \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

Canonical reproducible demo:

```bash
lua main.lua run \
  --github-profile slasten3826 \
  --include wolfcv \
  --target ./examples/vacancies/x5_agents.txt \
  --out ./wolfcv-demo-out
```

## Read these outputs first

1. `vacancy_diagnosis.md`
2. `machinecv.md`
3. `wolfcv.md`
4. `evidence_guard_report.md`

## How to read the result

- `vacancy_diagnosis.md`
  - what the vacancy really seems to want
- `machinecv.md`
  - what the machine thinks is actually supported by repo evidence
- `wolfcv.md`
  - the vacancy-aware CV projection
- `evidence_guard_report.md`
  - where the system distrusted wording or support

## Important

`WolfCV` may still produce:

- partial readings
- degraded vacancy diagnoses
- weak claim sets
- guarded or rejected projections

That is not automatically failure.
It is often the machine being honest about uncertainty or mismatch.

## If you want the deeper machine docs

Start here:

- [QUICKSTART.md](QUICKSTART.md)
- [README.md](README.md)
- [docs/table/WOLFCV_DEMO_RUN_v0.md](docs/table/WOLFCV_DEMO_RUN_v0.md)
- [docs/table/WOLFCV_MACHINE_ONBOARDING_v0.md](docs/table/WOLFCV_MACHINE_ONBOARDING_v0.md)
- [docs/table/WOLFCV_USER_FLOW_v0.md](docs/table/WOLFCV_USER_FLOW_v0.md)
- [docs/table/WOLFCV_OUTPUT_SURFACES_v0.md](docs/table/WOLFCV_OUTPUT_SURFACES_v0.md)
