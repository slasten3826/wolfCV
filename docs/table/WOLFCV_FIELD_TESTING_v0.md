# WolfCV :: Field Testing v0

## Status

Pencil document.

This document defines the first external testing posture for `WolfCV`.

Not broad release.
Not open launch.
Just the first real use outside the author/runtime loop.

---

## 1. Goal

Field testing is meant to answer:

- do people understand how to run `WolfCV`?
- do they understand which outputs matter?
- do they trust the result surfaces?
- where do they get confused?
- what breaks first in real use?

This phase is not for vanity feedback.
It is for product correction.

---

## 2. Who should test first

The first testers should be:

- technically strong people
- people with real repositories
- people with nonstandard or poorly legible profiles
- people capable of describing what felt wrong

Do not optimize for random general users yet.

---

## 3. What testers should receive

At minimum:

- `QUICKSTART.md`
- `HUMAN_README.md`
- one example vacancy
- one example command

The goal is to see whether this is enough.

If it is not enough,
the product is still too inward-facing.

---

## 4. What feedback matters

Useful feedback categories:

### A. Entry clarity

- did they understand what WolfCV is?
- did they understand what inputs they need?

### B. Run clarity

- did they understand how to launch it?
- did they know which command to use?

### C. Output clarity

- did they know which files to read first?
- did they understand `solid / partial / degraded`?

### D. Trust

- did they feel the machine was fair?
- did it feel too inflated?
- did it feel too weak?
- did guard behavior make sense?

### E. Breakdown points

- where did they get lost?
- where did they mistrust the system?
- where did they need the author to explain something?

---

## 5. What should be ignored

Do not overweight:

- vague praise
- vague “interesting idea”
- generic AI hype reactions

The important signal is:

```text
could they actually use the thing,
and where did usage break down?
```

---

## 6. First field-testing law

If the tester cannot understand:

- what to run
- what to read
- what to trust

then the product is not ready,
even if the machine itself is clever.

---

## 7. Short formula

```text
field testing is not asking whether people like the idea;
it is checking whether they can actually operate the machine.
```
