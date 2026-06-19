# Business Brief Structure Reference

Canonical structure and per-section rules for a Business Brief. Referenced from `SKILL.md`.

## Frontmatter

```yaml
---
project_name: "Project Name"
document_type: "Business Brief"
client_company: "Company Name"
sponsor: "Firstname Lastname"        # client decision maker / sponsor
engagement_lead: "Firstname Lastname"
mode: "Greenfield"                   # or "Refinement"
source: ""                           # populated in Refinement mode, e.g. "sow-project.docx, draft v. 2026-05-30"
status: "Draft"
created_date: "YYYY-MM-DD"
revision_date: "YYYY-MM-DD"
---
```

For any required field whose value is not yet known, set it to the literal string `"[OPEN]"` (e.g.
`sponsor: "[OPEN]"`, `engagement_lead: "[OPEN]"`) rather than leaving it blank - never invent a placeholder name.
`engagement_lead` defaults to the current user when that is known from context; otherwise `"[OPEN]"`.

Directly under the title, repeat a short banner for human readers (mode, status, owner), e.g.:

```
> **Mode:** Refinement (source: sow-project.docx, draft v. 2026-05-30)
> **Status:** Draft - input for SOW refinement and discovery questions
> **Owner:** «engagement lead»
```

## Inline markers (used throughout)

- `[OPEN]` / `[OPEN — owner, when]` - unanswered question. Re-collect all of these in section 17.
- `[ASSUMPTION]` - taken as true without confirmation. Give confidence in section 14.

Never replace an `[OPEN]` with an invented fact. Honesty about gaps is the document's purpose.

## Section structure

Headings use the numbered form `## N. Title`. Omit a section only if genuinely irrelevant.

```
# Business Brief: {Project Name}
> banner (mode / status / owner)

## 1. Executive Summary
(one tight paragraph: what the engagement is, headline scope, what "success" means - often a proof of
concept / decision input rather than measurable ROI; say so if true)

## 2. Business Context
(the situation that created the need: trigger "why now", sponsor, strategic context)

## 3. Problem Statement
(what hurts today, who feels it, the cost; quantify if known else [OPEN])

## 4. Desired Outcome
(what the client has afterwards; separate proof/decision outcomes from measurable business outcomes)

## 5. Stakeholders
| Role | Name / Function | Interest | Decision Power |

## 6. Users and Use Cases
(primary personas; UC1, UC2, ... top use cases; mark any out of scope)

## 7. Scope
### In Scope
### Out of Scope        (each exclusion with a reason)
### MVP / Phase 1
### Later Phases         (candidate change requests)

## 8. Functional Requirements
| ID | Requirement | Priority | Business Rationale | Acceptance Criteria |
(IDs F1, F2, ...; priority MUST / SHOULD / COULD; unresolved thresholds as [OPEN, when])

## 9. Non-Functional Requirements
| Area | Requirement | Target / Threshold | Notes |
(Performance, Availability, Refresh cadence, Security (auth/transport/audit), Concurrency, Scalability,
Compliance, Observability; "no commitment" is acceptable for pilots with a disclaimer)

## 10. Data and Integration Requirements
### Data Sources        (each with its unknowns)
### Key Entities
### Metric Definitions   (frequently [OPEN]; must be signed off before implementation - state this)
### Integration Requirements  (refresh cadence, read-only/scoped access, idempotency, retries)

## 11. Business Rules
(baseline/snapshot rules, thresholds, categorizations; mostly [OPEN] early)

## 12. Process Impact
### As-Is
### To-Be
### Change Impact        (per stakeholder group)

## 13. Success Metrics
(if measured by deliverables not KPI, say so)
### Discovery Questions  | # | Question | Ask whom | Purpose |   (baseline for future KPI)

## 14. Assumptions
| # | Assumption | Confidence |   (High / Medium / Low; promote low-confidence critical ones into Risks)

## 15. Dependencies & Client Responsibilities
**Client-side** (table):
| Obligation | Owner | Needed by | Status |
(derive one row per thing the client must provide or decide: system access, data owner, business owner, test user,
approval authority, metric definition, legal/security approval, sample data, expected business rule, acceptance
sign-off; if no owner exists, mark [OPEN] and raise a matching risk)

**Supplier-side:** ...
(for access/credentials, frame as "maintain/preserve" if you already have them, else "provide")

## 16. Risks
| # | Risk | P | I | Mitigation | Owner |

## 17. Open Questions
| # | Question | Owner | Target |   (consolidates every [OPEN] above)

## 18. Acceptance Criteria
(concrete testable "done" conditions (a)-(g); then state explicitly what is NOT accepted as success -
e.g. client-side adoption, ROI, scaling decision)

## 19. Recommended Next Steps
| # | Action | Owner | Target |

---

## SOW Readiness
(word-rated dimensions + one verdict; no numeric scores)

| Dimension | Rating |
| --- | --- |
| Business clarity | Strong / Adequate / Weak / Unknown |
| Scope stability | ... |
| Data / access readiness | ... |
| Stakeholder alignment | ... |
| Acceptance-criteria maturity | ... |
| Implementation risk | ... |
| Commercial dependencies | ... |

**Verdict:** one of
- Ready for SOW
- Ready for SOW with assumptions (list them)
- Not ready for SOW, discovery required
- Not suitable for fixed scope, recommend time & material / analytical phase

### Strengths
### Weaknesses
### Must be clarified before SOW signing
### Must be clarified before implementation
### Recommended next discovery questions
```

## Writing rules

- **Tone:** analytical, candid, senior BA. Unlike the SOW, the brief may name uncertainty, internal stretch goals,
  and risks plainly.
- **Tables** for stakeholders, requirements, assumptions, risks, open questions, next steps - they scan fast and
  force structured thinking. Prose for the narrative sections (1-4, 12).
- **Every threshold, metric, or definition that is not yet agreed is `[OPEN]`**, not a guess.
- **Acceptance criteria must be testable** (e.g. a reconciliation test with a tolerance), and must spell out what is
  explicitly outside acceptance.
- Avoid em dashes (`—`) in body prose where the house style forbids them; the section banner `>` lines are the
  exception.
