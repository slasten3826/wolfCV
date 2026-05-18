# WolfCV :: User Flow v0

## Status

Pencil document.

This document defines the first human-usable flow for `WolfCV`.

Not every future flow.
Just the first one that should become stable enough to share.

---

## 1. Canonical user

The first product user is not “everyone”.

The first real user is:

- a strong technical person
- with real repositories
- with a messy or nonstandard profile
- who wants help translating repo truth into hiring-readable form

This user is technical enough to:

- run CLI tools
- prepare a vacancy text file
- inspect markdown and JSON outputs

This matters because the first product flow does not need to be beginner-proof.
It needs to be honest and operable.

---

## 2. Canonical input

First product flow should require only these inputs:

- one GitHub profile or a set of local repos
- one vacancy text file

Optional inputs:

- notes file
- forbidden claims file

Anything beyond that should remain optional for now.

---

## 3. Canonical command

The first shareable happy path should feel like:

```bash
lua main.lua run \
  --github-profile <profile> \
  --include <repo> \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

or:

```bash
lua main.lua run \
  --repos ./repo1 ./repo2 \
  --target ./vacancy.txt \
  --out ./wolfcv-out
```

If the product cannot make this flow feel central and understandable,
the CLI is still too inward-facing.

---

## 4. Canonical output set

The first shareable run should produce:

- `machinecv.md`
- `vacancy_diagnosis.md`
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

The important distinction:

- markdown outputs are for reading
- JSON outputs are for inspection and future automation

---

## 5. Reading order for a user

The first user should be guided to read outputs in this order:

1. `vacancy_diagnosis.md`
2. `machinecv.md`
3. `wolfcv.md`
4. `evidence_guard_report.md`

Why this order:

- first understand the target
- then understand the extracted truth
- then see the translated CV surface
- then inspect where the machine distrusted itself

---

## 6. Failure surfaces

The user flow must make failure understandable.

Important failure classes:

- repo scan failure
- model failure
- degraded vacancy reading
- weak evidence extraction
- unsupported claim pressure
- guard rejection

The user should not need to grep traces just to know which class happened.

Traces remain important,
but first-line failure reading should be human-readable.

---

## 7. First external test

The first real external test should be:

- one technically strong repo-shaped candidate
- one real vacancy
- one full run
- one conversation afterward:
  - what felt clear
  - what felt noisy
  - what outputs they trusted
  - where they felt lost

That is more important than broad distribution right now.

---

## 8. Short formula

```text
one person
+ one repo stack
+ one vacancy
+ one run
= the first true product test
```
