# WolfCV :: Alpha Test Protocol v0

## Status

Pencil document.

This defines the first structured alpha test for `WolfCV` as a shareable product.

It is not a public launch protocol.
It is the first serious product check outside the author loop.

---

## 1. Goal

Alpha testing should answer:

- can another person run `WolfCV` without live guidance?
- can they understand what `WolfCV` is for?
- can they understand what to read first?
- can they trust the output surfaces enough to give useful feedback?
- where does the product still feel inward-facing?

The goal is not praise.
The goal is operational clarity.

---

## 2. Test posture

The alpha test should be:

- small
- controlled
- reproducible
- honest

This means:

- a small number of testers
- one clear command path
- one clear reading order
- one feedback template

---

## 3. Who should test first

First testers should be:

- technical people
- people with real repositories
- people with at least one real vacancy in hand
- people capable of saying exactly where a tool confused them

Do not optimize for broad public friendliness yet.

---

## 4. Test inputs

Each tester should use:

- either local repos or a public GitHub profile
- one real vacancy as a text file
- the default `DeepSeek flash` path

The first alpha round should avoid:

- complex custom provider setups
- private repo integrations
- experimental multi-model routing

---

## 5. Canonical run path

The alpha path should stay narrow.

Preferred commands:

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

### Reproducible demo

```bash
lua main.lua run \
  --github-profile slasten3826 \
  --include wolfcv \
  --target ./examples/vacancies/x5_agents.txt \
  --out ./wolfcv-demo-out
```

---

## 6. Reading order

Testers should read these first:

1. `START_HERE.md`
2. `vacancy_diagnosis.md`
3. `machinecv.md`
4. `wolfcv.md`
5. `evidence_guard_report.md`

If this order is not enough,
the product still needs simplification.

---

## 7. Success criteria

Alpha success does not mean:

- perfect wording
- perfect match quality
- universal role coverage

Alpha success means:

- the tester understood how to run it
- the tester understood what the main outputs mean
- the tester could tell when a result was strong or weak
- the tester could give concrete feedback without needing a long verbal walkthrough

---

## 8. Failure conditions

Alpha failure signals:

- the tester cannot tell what command to run
- the tester cannot tell what outputs matter
- the tester cannot tell whether a result is trustworthy
- the tester needs the author to explain the product step by step
- the tester cannot tell whether a weak result is a bug, mismatch, or honest guard behavior

---

## 9. What should be measured

For each tester, capture:

- what they used as source
- what vacancy they used
- whether they finished the run
- whether `START_HERE.md` was enough as an entry point
- whether the diagnosis felt right
- whether the truth layer felt fair
- where they got lost

---

## 10. Feedback channel

Use:

- [ALPHA_TEST_FEEDBACK.md](../../ALPHA_TEST_FEEDBACK.md)

The feedback should be short and concrete.

---

## 11. Law

```text
alpha testing is successful when another technical person can operate WolfCV
without the author standing next to the machine.
```
