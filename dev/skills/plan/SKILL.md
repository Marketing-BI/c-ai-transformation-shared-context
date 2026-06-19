---
name: plan
description: |
  Produce an implementation plan from a solution document (a Confluence page) as input — with systematic edge-case
  discovery, Fibonacci story-point estimates, a 5-agent parallel architectural review, scope-creep triage, and
  Confluence create/update on sign-off. The plan is a high-level architectural overview that concrete implementation is
  generated FROM later; it never contains code. Drafts section-by-section, never assuming unstated details.

  English triggers: "implementation plan", "write a plan", "plan this feature", "draft an implementation plan",
  "rework the plan", "estimate the work", "story-point the plan", "/dev:plan"

  České spouštěče: "implementační plán", "napiš plán", "naplánuj tuto funkci", "naplánuj implementaci",
  "přepracuj plán", "odhadni práci", "ohodnoť plán story pointy", "/dev:plan"
disable-model-invocation: true
model: opus
effort: xhigh
argument-hint: '[Solution document Confluence page URL/ID]'
allowed-tools:
  - mcp__atlassian__getAccessibleAtlassianResources
  - mcp__atlassian__getConfluencePage
  - mcp__atlassian__createConfluencePage
  - mcp__atlassian__updateConfluencePage
  - mcp__atlassian__searchConfluenceUsingCql
  - mcp__atlassian__getConfluencePageDescendants
  - mcp__atlassian__getPagesInConfluenceSpace
  - Read
  - Grep
  - Glob
  - Bash
  - Agent
  - AskUserQuestion
  - ExitPlanMode
  - TodoWrite
---

# Implementation Planning

Produce an implementation plan from a solution document, run a 5-agent parallel architectural review, triage the
results against scope, and create or update Confluence pages on sign-off.

## Input

The input to this skill is a **solution document on a Confluence page** — fetch it with
`mcp__atlassian__getConfluencePage` before drafting. If the user has not provided a Confluence page URL/ID for the
solution doc, ask for it before proceeding.

> Resolve the Atlassian `cloudId` once at the start of the run via `mcp__atlassian__getAccessibleAtlassianResources`
> (pick the resource whose `url` matches your site) and reuse it for every later Atlassian MCP call.

## Mode & Execution

ALWAYS switch into plan mode IMMEDIATELY when this skill is invoked, before any other action (including clarifying
questions). All drafting, review, and edits happen in plan mode. The ONLY way this skill ends is by asking the user
whether to create or update Confluence pages — never by prompting to proceed with implementation. Do NOT call
ExitPlanMode to kick off coding.

This skill MUST run on the **Opus** model with **extra-high (xhigh)** thinking/effort. If the current session is not
Opus or effort is below xhigh, tell the user to switch before continuing.

## No Assumptions — Always Ask

NEVER make assumptions while using this skill. If ANY detail is ambiguous, unspecified, or inferred rather than stated,
you MUST ask the user for clarification before proceeding. This applies to:

- Scope, feature boundaries, and non-goals
- Acceptance criteria and success metrics
- API shapes, data models, field types, naming
- Persistence choices, migrations, backfill strategy
- Auth, permissions, tenancy, visibility
- Integration points (external services)
- Non-functional requirements (performance, volume, retention, SLAs)
- Which existing code/components to reuse vs. build new
- Estimation inputs when effort is uncertain

Use `AskUserQuestion` with concrete options whenever possible. If you catch yourself writing "presumably", "I'll
assume", "by default", or picking an option the user didn't specify — STOP and ask instead. Record open items in the
plan's **Open Questions** section rather than guessing.

Every plan MUST also include an **Out-of-Scope / Follow-Ups** subsection (sibling to _Open Questions_). It captures
reviewer suggestions and user-rejected items that were intentionally deferred — each with a one-line rationale (which
reviewer raised it, why deferred). This preserves reviewer signal for future tickets without inflating the current
plan's estimate.

## Cite the Solution Doc — Don't Re-Gather

The solution doc (produced upstream by `/dev:solution-doc`, or authored by the client) is authoritative for the
dimensions it covers. **Verify against it; do not re-gather from the user what's already there.** Re-asking wastes the
user's time, invites contradictions between artifacts, and erodes the solution doc's role as source of truth.

For each planning dimension, before asking the user, **check the solution doc first**:

| Dimension                                                | Where in solution doc to look                               | Action                                   |
|----------------------------------------------------------|-------------------------------------------------------------|------------------------------------------|
| System boundaries / scope / non-goals                    | Scope & non-goals section                                   | Cite section + confirm with user         |
| User stories with acceptance criteria                    | Business cases / journeys (per-journey acceptance criteria) | Cite J-IDs; re-use enumeration           |
| Business rules                                           | Per-journey business rules                                  | Cite J-IDs; verify plan honors each      |
| Edge cases                                               | Per-journey edge cases                                      | Cite J-IDs; verify the plan handles each |
| Inter-story dependencies                                 | Inter-journey dependency map                                | Cite; use for task sequencing            |
| Materials (designs, copy, data specs)                    | Per-journey Materials & References                          | Link from plan; don't re-collect         |
| NFRs (latency, retention, availability, SLA, compliance) | Non-functional requirements                                 | Cite; design tasks to meet               |
| Data volume + growth                                     | NFR section                                                 | Cite; size indexes/capacity              |
| Reuse vs build calls                                     | Reuse vs build map                                          | Cite per task; don't redecide            |
| Integration intent                                       | Integration intent section                                  | Cite; tech shape from Decision Records   |
| Stakeholder map + Client Technical POC                   | Stakeholder map                                             | Cite; assign tasks accordingly           |
| Decision Records (carried forward)                       | Solution-doc Decision Records                               | Cite by DR-ID; do not re-litigate        |

**Citation format.** When citing the solution doc, use the smallest stable reference: journey IDs (`J1`, `J2`, …)
for journey-scoped items, Decision Record IDs (`DR-001`, `DR-002`, …) for decisions, and section headings for
everything else. DR-IDs originate in the solution doc and are carried forward verbatim; the plan never re-issues or
renumbers them. If a DR-ID referenced in the solution doc has no matching block, that's a solution-doc gap — escalate
via the **Upstream Feedback Protocol** below, do not invent the decision.

Re-gather **only** when the solution doc has gaps (look for the doc's own **Open Questions** and **Blockers** —
those are the authorized re-gather list). If the solution doc is silent on a dimension the plan needs, treat it as
an Open Question, not an assumption.

If you find a **contradiction** between the solution doc and what the user is now telling you, stop and surface it
explicitly — do not silently overwrite. The solution doc may need to be updated first (and re-published), or the
user's new input may be a correction. Either way, the user decides.

## Edge Cases & Business Case Coverage

A plan is incomplete if it only describes the happy path. The solution doc enumerates edge cases per journey (see
its per-journey **Edge cases** field). Your job is to **verify the plan answers each one**, not to re-enumerate from
scratch.

For every edge case the solution doc lists: either (a) describe how the plan handles it in the relevant task, or
(b) record it in **Open Questions** with concrete options — NEVER silently pick a default.

If the solution doc's edge-case list is suspiciously thin for a journey, **flag it as a gap in the solution doc**
(not as a plan-side todo) — and walk the dimensions below to surface what's missing. The fix is to update the
solution doc, not to silently extend it in the plan.

Dimensions to walk when the solution doc is silent or thin (use this as the gap-discovery checklist, not a
re-enumeration of what's already there):

- **Input variations** — empty / missing, boundary values (0, 1, max, negative, very large, unicode, long strings),
  malformed or invalid payloads, legacy data missing newly-added fields.
- **User & permission variations** — first-time user / empty state, partial permissions (can see X but not Y),
  cross-tenant visibility and leakage, mid-flow role or permission changes.
- **State & concurrency** — concurrent edits on the same entity, stale data / optimistic-concurrency failures, retry
  semantics and idempotency of mutations, partial failures in multi-step flows, races between async workers (scheduled
  jobs, event consumers).
- **Temporal** — time zones, DST, leap years, long-running operations (timeout, resumption), rate limits and quota
  exhaustion on external APIs.
- **Failure & recovery** — each external integration unreachable / slow / 4xx / 5xx / unexpected response shape,
  rollback strategy when a multi-step flow fails halfway, user-facing error UX, abandonment mid-flow (is state
  consistent?).
- **Business-rule completeness** — alternate happy paths the solution doc implies but doesn't spell out, regressions in
  adjacent features, bulk vs. single-item behavior, undo / soft-delete / restore, audit trail for compliance-sensitive
  actions.

Don't just enumerate edge cases — verify the plan answers each one. The Business Case Evaluator reviewer will flag gaps;
catch them before the review runs. If the solution doc is silent on an edge case, that's an **Open Question**, not an
assumption.

## When to Use

- User asks to create, draft, or rework an implementation plan.
- User references a planning checklist or a Confluence page that needs restructuring into a plan.
- Any task that requires estimation in Fibonacci SP + multi-agent architectural review.

## Checklist Source of Truth (Optional)

If your organization maintains a canonical implementation-plan checklist in Confluence, fetch it at the start of every
planning session and conform the plan to it — do NOT copy it into this skill:

```text
mcp__atlassian__getConfluencePage
  cloudId: <cloudId from getAccessibleAtlassianResources>
  pageId: <your org's checklist page ID>
  contentFormat: "markdown"
```

If no such checklist exists, use the section structure below (sections 1–9) as the default plan shape. Either way, the
plan-quality discipline in this skill (no code, feature-based decomposition, Fibonacci estimates, edge-case coverage,
multi-agent review, scope triage) always applies.

## Plan Detail Level

The plan is a **high-level architectural overview**. Concrete implementation (exact field types, DTO shapes, query
bodies, file edits) is generated FROM the plan later — it does NOT belong in the plan itself.

Plans MUST NOT contain code snippets. They SHOULD describe architecture at the level needed to estimate, review, and
hand off — no lower:

- **API endpoints** — method, path, purpose; request/response described by the entities involved, not field-by-field
  DTOs.
- **DB models & schemas** — entities, key attributes, and relations; skip exhaustive column types/constraints unless
  load-bearing for the design.
- **Migrations** — what changes conceptually (new table, new column, backfill), not DDL.
- **Data flow** — how data moves between services/layers, and where the boundaries are.

If you find yourself specifying things only the implementer needs (exact types, validation rules, file paths, line
numbers), you're too deep — pull back up.

**Always include reasoning.** For every non-trivial change — new endpoint, schema change, new service, migration,
integration point — state _why_ it is required (the driving requirement, constraint, or trade-off being resolved).
Reviewers and future implementers must be able to tell intent from incidental detail. A change listed without a reason
is a red flag; either add the reason or drop the change.

**Exception — pseudocode for non-trivial algorithms:** When the plan involves a harder algorithm whose correctness or
shape isn't obvious from prose (e.g. custom scheduling, deduplication, graph traversal, consistency/merge logic), you
MAY include language-agnostic pseudocode to describe it. Keep it minimal — steps and control flow only, no real syntax,
no imports, no framework calls. Prefer prose + tables whenever they suffice.

## Task Decomposition — Feature-Based, Independently Deployable

Tasks in the plan are **feature-based increments**, NOT technical micro-steps. Each task represents a meaningful slice
of the feature request — something a stakeholder would recognize — and it MUST be deployable to production on its own
without breaking the running application.

What a task looks like:

- A user-visible capability, end-to-end slice, or a self-contained backend behavior that delivers value or unblocks the
  next slice.
- Spans whatever layers it needs (DB + API + UI + integration) bundled into one deployable unit.
- Sized against the Fibonacci scale below. If it exceeds 8 SP, split along feature/capability lines — not along layers.

What a task is NOT:

- "Add field to interface", "create DTO", "add migration", "wire controller" — these are implementation steps inside a
  task, not tasks.
- A purely technical layer split (backend-only task, then frontend-only task) when the feature only makes sense
  end-to-end.

Deployability rules (apply within and across tasks):

- **Backwards-compatible by default.** Additive changes ship before any removal or rename. **Exception:** fundamental
  changes MAY break backwards compatibility, but ONLY when the user has explicitly confirmed and verified the break is
  acceptable. Use `AskUserQuestion` to surface the break, its blast radius (affected consumers, data, deploys), and the
  migration window — then record the confirmation in the plan's **Open Questions / Decisions** section before
  proceeding.
- **Expand → migrate → contract.** For schema/API reshaping, use this as a _task-ordering_ pattern across feature slices
  — not as an excuse to generate three micro-tasks per field change.
- **No dangling references** between tasks — a task must not depend on something a later task introduces.
- **Feature flags / dark launches** when a feature spans multiple deploys and must stay invisible until ready.
- **Migrations deploy before the code that needs them**; rollbacks must be safe with the previous release still running.
- **Cross-service changes** order producer-before-consumer and stay compatible with the previous consumer version
  during rollout.

Each task SHOULD state its **deploy boundary** — what ships, and what invariants hold before/after. If a task can't be
deployed alone, rethink the slice; don't shatter it into plumbing tickets.

## Estimation

Each task MUST include a Fibonacci story point estimate:

| SP | Max Effort |
|----|------------|
| 1  | < 2 hours  |
| 2  | < 4 hours  |
| 3  | < 8 hours  |
| 5  | < 16 hours |
| 8  | < 3 days   |
| 13 | < 1 week   |
| 21 | < 2 weeks  |

Tasks estimated at 8+ SP MUST be broken into smaller subtasks.

**Totals:** SP are NOT additive. Sum the max-effort hours behind each task, then convert total hours back to the nearest
SP. Example: 2 SP (4h) + 2 SP (4h) = 8h → 3 SP. The plan summary must show both total hours and equivalent SP.

**Buffers** (apply on top of raw implementation hours, tune defaults to your team's process):

| Buffer                           | Default                   |
|----------------------------------|---------------------------|
| Unforeseen implementation issues | +20%                      |
| Internal QA / code review        | +10%                      |
| Client review / code review      | +10%                      |
| PM review / admin                | ~30 min per person-day    |

## Plan Review (5 Parallel Sub-Agents)

**When:** After drafting the complete plan (sections 1–9) AND after the edge-case walk above, before sign-off.

**Reviewer output feeds the Review Triage step (below) — it is advisory input, never auto-merged into the plan.**

**How:** Dispatch 5 sub-agents IN PARALLEL (single message, 5 `Agent` tool calls). Use the dedicated `dev` reviewer
agents via the `subagent_type` parameter — each agent's review lens is baked into its agent definition, so do NOT load
any persona file yourself.

Each agent receives:

1. The full draft plan (or its path).
2. Instruction to review and return structured feedback.
3. For the Business Case Evaluator: ALSO pass the solution / requirements document (path or contents) so it can check
   coverage, AND ask it to explicitly audit the Edge Cases & Business Case Coverage section against every business case
   in the solution doc.
4. For the Solution Architect: ALSO pass the solution document (path or contents). Its lens is distinct from BCE — it
   checks whether the **plan honors the solution doc's shape** (journeys, business rules, edge cases, reuse-vs-build
   calls, NFRs, Decision Records carried forward by **DR-ID**) rather than whether requirements are covered
   task-by-task. Specifically flags: silent re-decisions of an existing DR-ID, missing DR-ID citations where a
   decision is referenced, contradictions between plan tasks and the cited DR, and plan-side drift from the
   solution doc's journey/NFR shape.

| Reviewer                | `subagent_type`                  | Key Focus                                                                                                                                                                                |
|-------------------------|----------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| BE Architect            | `dev:backend-architect`          | API design, DB design (normalization, indexes, constraints, query patterns at scale), service boundaries                                                                                 |
| Security Reviewer       | `dev:security-reviewer`          | Auth completeness, data security, OWASP Top 10, input validation, secrets                                                                                                                |
| UI Architect            | `dev:ui-architect`               | Component design; verify BE provides all inputs needed for filtering/sorting/pagination/retries; UX completeness                                                                         |
| Business Case Evaluator | `dev:business-case-evaluator`    | Requirements coverage vs solution doc, use-case completeness, business rules, acceptance criteria, stakeholder outputs                                                                   |
| Solution Architect      | `dev:solution-architect`         | Plan ↔ solution-doc shape alignment: journeys/business rules/edge cases honored, reuse-vs-build respected, Decision Records carried forward, no plan-side re-decisions or contradictions |

**After all 5 agents return, run the Review Triage step (below) before any plan edit.**

## Review Triage (Anti-Scope-Creep Gate)

**Why this exists.** Expert reviewers naturally surface improvements; without a filter, every suggestion lands in the
plan and the draft balloons. Reviewer output is advisory — the planner's job is to protect scope, not to fold in
everything that was raised.

**Triage every reviewer item — Critical and Recommendation alike — into one of three buckets:**

- **Blocker** — without this, the implementation will fail or produce a wrong result for a requirement _stated in the
  solution doc_. Each Blocker MUST cite (quote or reference) the specific requirement, business case, or concrete
  failure mode in the solution doc that anchors it.
- **In-scope improvement** — improves the quality of work already in the plan without adding new capability, surface
  area, or hardening beyond what the solution doc requires.
- **Out-of-scope** — adds capability, hardening, observability, alternate architecture, or edge-case handling not
  required by the solution doc. **Default disposition: defer to Out-of-Scope / Follow-Ups.**

**Anchor rule.** Any suggestion that cannot cite a requirement, business case, or failure mode rooted in the solution
doc is **Out-of-scope by default**. No solution-doc anchor → not a Blocker, regardless of how the reviewer phrased it.

**Planner-as-defender role.** For every item the planner classifies as Blocker, briefly steelman _not_ including it
("would a senior engineer push back on this?").

**Effort delta check.** Compute draft total effort (pre-review) → projected total if all Blockers were folded in. If
growth exceeds **+25%**, mark the triage table with a prominent warning callout. This is a flag for user attention, not
a halt or veto.

**User-as-final-authority gate.** Present the full triage table to the user before any plan edit. The table MUST show,
for each suggestion: reviewer, suggestion summary, bucket (Blocker / In-scope / Out-of-scope), solution-doc anchor
(or explicit "no anchor"), planner's recommendation, and the effort-delta warning if tripped. Do NOT pre-fold anything.
The user decides per item what enters the plan.

**After user decisions.**

1. Apply only the user-approved items to the plan.
2. Record every Out-of-scope item AND every user-rejected item in the plan's **Out-of-Scope / Follow-Ups** subsection
   with a one-line rationale (which reviewer raised it, why deferred). Reviewer signal is preserved for future tickets
   without inflating this plan's estimate.
3. Present the final review summary to the user before sign-off.

## Upstream Feedback Protocol

When this skill discovers a gap, contradiction, or missing decision in its **upstream artifact** (the solution doc),
the response is **not** to silently extend or work around it. The solution doc is the planner's contract; patching
its gaps at plan-time fragments the source of truth and means the next plan iteration faces the same gap.

**Triggers** — invoke this protocol when you find:

- A DR-ID referenced in the solution doc has no matching Decision Record block.
- A journey acceptance criterion contradicts a stated NFR, business rule, or another journey.
- A required capability has no reuse-vs-build call.
- A user role is referenced in a journey but absent from the role/permission matrix.
- The solution doc's edge-case list for a journey is suspiciously thin given the journey's complexity.
- A journey requires a decision the solution doc never made (and that's not a tech-shape decision already captured as a
  Decision Record).
- The user provides input during planning that **contradicts** the solution doc (rather than fills a gap in it).

**Steps:**

1. **Pause planning.** Do not continue the affected section or task.
2. **Document the gap precisely** — quote the upstream text (or DR-ID / J-ID), state what's missing or
   contradicted, and name the plan section / task that exposed it.
3. **Present to the user** with three options:
   - **(a) Update upstream** — pause here, the user runs `/dev:solution-doc` to amend the solution doc (fix the
     contradiction, expand the journey, add the missing DR). On return, re-fetch the updated Confluence page verbatim
     and resume.
   - **(b) Record as plan-level Open Question** — only if the gap is genuinely a planning concern (e.g. task
     sequencing) and not a solution-doc shape issue. Do **not** use this option to absorb solution-doc gaps.
   - **(c) Accept the gap explicitly** — only if the user judges it not worth fixing now. Record under **Open
     Questions** with the upstream owner and the impact on the plan's correctness.
4. **Re-fetch if (a) was chosen.** Re-fetch the Confluence solution-doc page in full via
   `mcp__atlassian__getConfluencePage`. Refresh carried-forward DRs and journey enumerations. Do not work from
   memory of the prior version.
5. **Resume planning** from the paused section.

The Solution Architect reviewer (sub-agent #5) is specifically tasked with surfacing missed protocol triggers — if
its review flags a "silent re-decision" or "missing carry-forward", that's a protocol violation, not a
recommendation.

## Confluence Export (Post Sign-Off)

**When:** After the plan is finalized and approved.

**Ask the user:** whether to export, and for a parent page URL or ID.

**Create 3 child pages** under the parent using `mcp__atlassian__createConfluencePage`:

1. **`[Feature Name] — Implementation Plan`** — full plan (sections 1–9).
2. **`[Feature Name] — Checklist`** — task breakdown with estimates, assignees, status.
3. **`[Feature Name] — Open Questions`** — unresolved questions, assumptions, pending decisions.

If the user asks to update an EXISTING page rather than create new children, use `mcp__atlassian__updateConfluencePage`
and keep the existing title/parent.

> The published plan is the input to `/dev:plan-to-jira-tickets`, which creates Stories + Sub-tasks under an existing
> Jira Epic from it.

## Workflow Summary

1. Resolve the Atlassian `cloudId`. Fetch the org checklist page (if one exists) — every session.
2. Fetch the solution-doc Confluence page and read it in full.
3. Explore the relevant codebase (use Explore sub-agents for large scope).
4. Draft sections 1–9 (per the org checklist, or the default shape above), **citing the solution doc by J-ID / DR-ID /
   section** rather than re-gathering (see "Cite the Solution Doc — Don't Re-Gather").
5. If at any point you discover a solution-doc gap or contradiction, invoke the **Upstream Feedback Protocol** —
   pause, document, present options to the user, re-fetch on patch, resume.
6. Run the 5-agent parallel review.
7. Run the **Review Triage** step: classify every reviewer suggestion (Blocker / In-scope / Out-of-scope), anchor each
   Blocker to the solution doc, compute the effort delta, and present the triage table to the user. Apply only
   user-approved items. Record everything else under **Out-of-Scope / Follow-Ups**. Never auto-fold reviewer output.
8. On sign-off, ask the user whether to create new Confluence pages or update an existing one. Never ask to proceed with
   implementation.
</content>
</invoke>
