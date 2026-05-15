# WolfCV — internal data model v0.1

## Status

Legacy reference draft.

This document belongs to the earlier pre-`mapp` specification layer.
Do not delete it.
Use it as background structure, not as the final current runtime contract.

Read current documents first:

- `WOLFCV_RUNTIME_AND_STAGE_CONTRACTS_v0.md`
- `IMPLEMENTATION_STATUS_v0.md`

This document defines the minimum internal structured layer required for WolfCV to work as an evidence-to-CV compiler rather than a plain text generator.

Core principle:

```text
artifact -> evidence -> claim -> translation -> validation -> gap
```

If this chain is not explicit in data, `EvidenceGuard` becomes decorative.

---

## 1. Why this layer exists

WolfCV must not operate only on free text.

It needs a structured middle layer that can answer:

```text
Which artifact supports this claim?
How strong is that support?
What is the scope of the support?
What wording is safe?
What wording is forbidden?
What does the vacancy actually ask for?
What is missing?
What bridge artifact could close the gap honestly?
```

This layer is the machine substrate for:

- `MachineCV`
- `Wolf Adapter`
- `LegacyHR`
- `EvidenceGuard`
- `Gap Planner`

---

## 2. Core entities

WolfCV MVP should define at least these entities:

```text
Repository
Artifact
Evidence
Claim
Vacancy
CVDraft
GuardResult
Gap
```

Optional later entities:

```text
CandidateProfile
RoleFit
KeywordCluster
BridgeProject
LegacyHRReport
```

---

## 3. Repository

A repository is a source container.

### Minimum fields

```json
{
  "repo_id": "repo_processcards",
  "source_type": "local",
  "local_path": "/home/slasten/Документы/stack/projects/processcards",
  "remote_url": null,
  "repo_name": "processcards",
  "owner": "slasten3826",
  "branch": "main",
  "commit_ref": "HEAD"
}
```

### Notes

- `source_type` can be `local`, `github`, or later `archive`.
- `commit_ref` is important for reproducibility.
- A repository is not itself evidence. It is a source domain.

---

## 4. Artifact

An artifact is a concrete file or file-like source unit.

### Minimum fields

```json
{
  "artifact_id": "art_processcards_grant_md",
  "repo_id": "repo_processcards",
  "path": "trumps/GRANT.md",
  "kind": "file",
  "language": "markdown",
  "class": "DESIGN",
  "summary": "Trump law document for GRANT wildcard-column mechanic.",
  "confidence": 0.92,
  "role_tags": ["system_design", "game_rules", "formal_spec"],
  "visibility": "normal"
}
```

### Allowed classes

```text
CODE
SPEC
DESIGN
RESEARCH
PROTOCOL
CANON
META
PHILOSOPHY
DOCS
INDEX
MEDIA
DRAFT
CONFIG
TEST
```

### Notes

- `summary` is generated or reviewed text, not source truth.
- `class` is classification, not value judgment.
- `visibility` can later support exclusion rules like `noise`, `generated`, `binary_only`.

---

## 5. Evidence

Evidence is the minimum support-bearing unit.

An evidence item should be stronger than raw file summary and smaller than a full CV claim.

### Minimum fields

```json
{
  "evidence_id": "ev_0001",
  "statement": "Candidate designed and documented a wildcard-column rules system with compiler implications.",
  "source_artifacts": ["art_processcards_grant_md"],
  "source_spans": [
    {
      "artifact_id": "art_processcards_grant_md",
      "loc_hint": "sections 1-6"
    }
  ],
  "evidence_type": "DESIGN",
  "strength": "medium",
  "scope": "prototype",
  "supports_skills": ["system_design", "formal_specification", "rule_engineering"],
  "limitations": ["not evidence of commercial deployment"],
  "confidence": 0.81
}
```

### Required interpretation fields

```text
strength: weak | medium | strong
scope: concept | prototype | runnable | production_like | production
```

### Notes

- `statement` must be factual and local.
- `limitations` are first-class data, not afterthoughts.
- Evidence must be allowed to support multiple future claims.

---

## 6. Claim

A claim is a candidate-facing or recruiter-facing statement that may appear in CV output.

Claims are what `EvidenceGuard` evaluates.

### Minimum fields

```json
{
  "claim_id": "cl_0001",
  "text": "Designed formal system specifications and machine-readable interaction architectures.",
  "normalized_skill_tags": ["system_design", "technical_specification", "ai_interaction_architecture"],
  "support_level": "SUPPORTED",
  "supporting_evidence_ids": ["ev_0001"],
  "risk_level": "low",
  "scope": "prototype",
  "safe_for_cv": true,
  "safer_wording": "Designed formal specifications and architecture documents for machine-oriented systems.",
  "forbidden_reason": null
}
```

### Support levels

```text
SUPPORTED
PARTIALLY_SUPPORTED
RITUAL_TRANSLATION
UNSUPPORTED
FORBIDDEN
```

### Risk levels

```text
low
medium
high
```

### Notes

- `Claim` is where truth pressure and ritual pressure meet.
- The same `Evidence` can support several claims with different support levels.
- `scope` should survive into phrasing decisions.

---

## 7. Vacancy

A vacancy is not just raw text. It must be normalized into machine-usable pressure.

### Minimum fields

```json
{
  "vacancy_id": "vac_0001",
  "title": "ML Engineer (LLM)",
  "raw_text_path": "./vacancies/ml_engineer_llm.txt",
  "keywords": ["llm", "rag", "docker", "kubernetes", "nlp", "prompt engineering"],
  "hard_requirements": [
    "experience with llm/nlp projects",
    "docker",
    "kubernetes"
  ],
  "soft_requirements": [
    "full-cycle ownership",
    "local ml infrastructure"
  ],
  "domain_tags": ["llm", "nlp", "ml_platform"],
  "seniority_signals": ["full cycle", "requirements analysis", "production integration"],
  "ritualization_score": 0.58
}
```

### Notes

- `ritualization_score` is heuristic, not truth.
- Vacancy parsing should separate task signals from ritual tokens.
- `hard_requirements` and `soft_requirements` should remain text-like in MVP.

---

## 8. CVDraft

A CVDraft is a generated output layer, not a truth entity.

### Minimum fields

```json
{
  "cvdraft_id": "cv_0001",
  "vacancy_id": "vac_0001",
  "summary": "ML/LLM-oriented system designer with evidence in retrieval-like workflows, technical specification, and AI interaction architecture.",
  "role_title": "ML Engineer / LLM Systems Engineer",
  "skill_blocks": [
    "LLM workflows",
    "technical specifications",
    "system design",
    "prototype engineering"
  ],
  "project_bullets": [
    "Designed machine-facing system architecture and protocol-like interaction layers.",
    "Built prototype-level AI workflow tooling and structured evidence systems."
  ],
  "claim_ids": ["cl_0001"],
  "target_mode": "wolfcv"
}
```

### Notes

- `target_mode` can be `machinecv` or `wolfcv`.
- Text blocks should be derivable from claim sets.
- Free-text generation should still keep claim linkage.

---

## 9. GuardResult

GuardResult is the structured output of `EvidenceGuard`.

### Minimum fields

```json
{
  "guard_id": "gd_0001",
  "claim_id": "cl_0001",
  "status": "SUPPORTED",
  "reason": "Claim is directly grounded in design artifacts and scoped as design/prototype work.",
  "recommended_wording": "Designed formal specifications and machine-oriented system architectures.",
  "blocking_evidence_ids": [],
  "missing_evidence": [],
  "review_required": false
}
```

### Notes

- One `GuardResult` per evaluated claim is enough for MVP.
- `blocking_evidence_ids` is useful when a stronger wording fails.
- `review_required` lets the system admit uncertainty.

---

## 10. Gap

A gap is not just a missing keyword.

It is a vacancy pressure point that current evidence does not safely satisfy.

### Minimum fields

```json
{
  "gap_id": "gap_0001",
  "vacancy_id": "vac_0001",
  "label": "dockerized inference/service evidence",
  "severity": "high",
  "related_keywords": ["docker", "service deployment", "local infra"],
  "current_support": "UNSUPPORTED",
  "reason": "No direct artifact shows containerized service packaging or runtime deployment evidence.",
  "bridge_suggestion": "Build a minimal FastAPI service around an existing model/tool and package it with Docker.",
  "bridge_size": "small",
  "claims_affected": ["cl_0007", "cl_0011"]
}
```

### Gap severity

```text
low
medium
high
critical
```

### Bridge size

```text
small
medium
large
```

### Notes

- `Gap` must be explainable in plain language.
- `bridge_suggestion` is not decorative; it is an honest signal-repair plan.

---

## 11. Required graph links

The system must preserve explicit links.

Minimum graph:

```text
Repository -> Artifact
Artifact -> Evidence
Evidence -> Claim
Claim -> CVDraft
Claim -> GuardResult
Vacancy -> Claim
Vacancy -> Gap
Claim -> Gap
```

### Practical invariant

Every CV sentence must be traceable backwards:

```text
CV sentence
-> claim_id
-> evidence_id
-> artifact_id
-> file path / source hint
```

If that chain breaks, WolfCV is no longer auditable.

---

## 12. Minimal JSON packets

For MVP, the program should be able to emit at least these files:

```text
artifacts.json
repository_index.json
evidence_map.json
claims.json
vacancy_map.json
guard_results.json
gap_report.json
```

Human-facing files can be derived from them:

```text
machinecv.md
wolfcv.md
evidence_guard_report.md
legacyhrcv_report.md
delta_report.md
```

---

## 13. Core invariants

```text
Artifacts are not claims.
Evidence is not CV phrasing.
Claims must be guardable.
Vacancy pressure must be explicit.
Missing evidence must not be hidden.
Gap suggestions must create real future evidence, not rhetorical tricks.
```

And the central invariant:

```text
Every strong recruiter-facing phrase must remain traceable to bounded evidence.
```

---

## 14. MVP implementation priority

The first implementation should focus on these transformations only:

```text
repo -> artifact
artifact -> evidence
evidence -> claim
claim + vacancy -> wolf wording
claim -> guard result
vacancy + claims -> gap list
```

Do not start with:

```text
perfect scoring
multi-user infra
beautiful UI
full GitHub crawler
advanced ATS prediction
```

---

## 15. One-line definition

```text
WolfCV's internal data model is the structured layer that makes evidence traceable, claims guardable, vacancy pressure explicit, and honest signal repair possible.
```
