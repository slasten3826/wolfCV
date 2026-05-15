# WolfCV — application specification v0.1

## Status

Legacy reference draft.

This document belongs to the earlier pre-`mapp` specification layer.
Do not delete it.
Do not treat it as the primary current runtime law.

Read current documents first:

- `WOLFCV_MAPP_YELLOWPRINT_v0.md`
- `WOLFCV_RUNTIME_AND_STAGE_CONTRACTS_v0.md`
- `WOLFCV_DEEPSEEK_PROVIDER_v0.md`
- `IMPLEMENTATION_STATUS_v0.md`

This document defines what WolfCV is as an application, what problem it solves, what it must do, what it must not do, and what its first useful product contour should be.

---

## 1. Product definition

WolfCV is an evidence-to-CV translation system.

It reads real technical artifacts:

- repositories
- code
- documentation
- specifications
- research notes
- design docs

and converts them into:

1. an evidence-grounded profile
2. a job-facing CV
3. a legacy HR simulation
4. a falsification boundary report
5. a gap-and-bridge plan

WolfCV is not a lie generator.

Canonical definition:

```text
WolfCV is a ritual compatibility compiler.
```

---

## 2. Why it exists

Many technically strong candidates are under-read by hiring systems because their signal is:

- too deep
- too distributed across repositories
- too machine-facing
- too non-standard in terminology
- too architectural to fit shallow CV scanning

Legacy hiring systems reward:

- familiar wording
- role labels
- known tool names
- chronology legibility
- social readability
- shallow keyword compliance

This creates a translation problem, not only a competence problem.

WolfCV exists to solve:

```text
real evidence
-> ritual legibility
without hard falsification
```

---

## 3. What WolfCV does

WolfCV should:

- ingest repository evidence
- classify artifacts
- extract bounded evidence statements
- derive guarded claims
- parse vacancy pressure
- generate a vacancy-facing CV draft
- simulate shallow HR reading
- validate claims against evidence
- detect gaps
- suggest honest bridge artifacts to close gaps

---

## 4. What WolfCV does not do

WolfCV must not:

- invent employers
- invent dates
- invent degrees
- invent production deployments
- invent business metrics
- invent team structures
- fabricate open-source authorship
- hide unsupported claims under confident phrasing

WolfCV may translate.

WolfCV may not fabricate.

---

## 5. Internal machine structure

WolfCV is the outer application.

Its internal machines are:

```text
MachineCV
Wolf Adapter
LegacyHR
EvidenceGuard
Gap Planner
```

### MachineCV

Truth/evidence engine.

Answers:

```text
What is actually present?
What is supported?
What is only partial?
What is unsupported?
What roles fit the evidence?
```

### Wolf Adapter

Ritual translator.

Answers:

```text
How should supported evidence be phrased
to survive first contact with the target vacancy?
```

### LegacyHR

Shallow filter simulator.

Answers:

```text
Will the wording pass a ritual scan?
What keywords or signals are missing?
What will look strange too early?
```

### EvidenceGuard

Boundary checker.

Answers:

```text
Which claims are safe?
Which claims are stretched but acceptable?
Which claims are unsupported?
Which claims are forbidden?
```

### Gap Planner

Signal repair planner.

Answers:

```text
What evidence is missing?
What small real project could close that gap honestly?
```

---

## 6. Core product pipeline

The canonical processing chain is:

```text
artifact -> evidence -> claim -> translation -> validation -> gap
```

This is the product's real center.

If this chain is not explicit, WolfCV collapses into generic AI text generation.

---

## 7. User inputs

WolfCV MVP should accept:

- local repository paths
- optional GitHub repository URLs
- optional GitHub username
- target vacancy text
- optional candidate notes
- optional forbidden claims list

---

## 8. Primary outputs

WolfCV should produce:

- `machinecv.md`
- `wolfcv.md`
- `legacyhrcv_report.md`
- `evidence_guard_report.md`
- `delta_report.md`
- `gap_report.md`
- structured JSON evidence artifacts

---

## 9. Modes of operation

WolfCV should support one main path and several debug stages.

### Main path

```text
wolfcv run
```

This performs the whole pipeline.

### Stage paths

```text
wolfcv truth
wolfcv translate
wolfcv legacy-test
wolfcv guard
wolfcv gap
```

These are used for inspection, debugging, and iterative refinement.

---

## 10. Vacancy sensitivity

WolfCV must distinguish at least two vacancy shapes:

### Clean / task-heavy vacancy

Characteristics:

- real work is visible in the description
- responsibilities dominate over stack theater
- translation can stay closer to evidence shape

### Ritual-heavy vacancy

Characteristics:

- long checklist of familiar tools
- high ATS / recruiter token pressure
- tribal stack markers
- greater risk of false-fit temptation

This should influence translation aggressiveness and guard strictness.

---

## 11. Honest bridge principle

A missing signal should not force a binary choice between:

- lying
- giving up

WolfCV must support a third path:

```text
honest bridge work
```

Meaning:

- identify missing but important evidence
- suggest a small real project
- create future support rather than fake current support

This is a core product differentiator.

---

## 12. MVP boundary

First implementation should be:

- local-first
- CLI-first
- evidence-centered
- reviewable by a human

First implementation should not attempt:

- perfect ATS prediction
- autonomous career strategy
- full public GitHub crawling
- polished GUI
- magical objectivity claims

---

## 13. Success criterion

WolfCV is useful if it can do all three:

1. preserve strong weird technical signal
2. translate that signal into recruiter-legible form
3. stop the user from crossing into hard falsification

---

## 14. One-line definition

```text
WolfCV is an evidence-to-CV compiler that turns repository truth into hiring-compatible form without allowing that translation to become false history.
```
