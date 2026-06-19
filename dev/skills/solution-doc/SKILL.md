---
name: solution-doc
description: |
  Produce the single solution document that bridges architecture and planning — gather product/business context,
  settle the architecture decisions as Decision Records (DR-IDs), shape the solution journey-by-journey with approval
  checkpoints, and publish to Confluence as the input artifact for `/dev:plan`. It is the one design artifact: the
  architecture baseline (deployment, stack, integrations, data model, auth) lives inside it as Decision Records, so
  there is no separate architecture doc. Drafts section-by-section, never assuming domain specifics.

  English triggers: "solution document", "solution doc", "write a solution doc", "bridge artifact for planning",
  "settle the architecture", "record this decision", "solution design", "/dev:solution-doc"

  České spouštěče: "solution dokument", "řešitelský dokument", "návrhový dokument", "napiš solution doc",
  "ustáleme architekturu", "zaznamenej rozhodnutí", "návrh řešení", "/dev:solution-doc"
---

# Solution Document Generator

Produce the **solution document** — the single bridge artifact between a settled architecture (deployment, stack,
integrations, data model, auth) and an implementation plan (tasks, estimates, sequencing). The solution doc answers
*what* is being built, *for whom*, *why*, and *what good looks like* — in product/business shape — **and carries the
settled architecture decisions inside it as Decision Records (DR-IDs)**, so downstream artifacts cite a single source.

> **This is the one design artifact.** There is no separate architecture doc. The architecture baseline is captured
> here: hard constraints up front, and every tech choice recorded as a structured **Decision Record** rather than
> inline prose. If a standalone architecture doc happens to exist, it is treated as a *linked* source whose Decision
> Records are carried forward verbatim — but the solution doc is self-contained and authoritative on its own.

> **Sibling skills:** This skill produces the input for `/dev:plan` (sibling in `dev/skills/`). It can run standalone.
> When a decision needs to be made during drafting, offer to invoke `/dev:compare`. If the *what* is still fuzzy,
> run a brainstorming skill first (e.g. the `superpowers` plugin's `brainstorming` skill, if installed) before this
> one.

## Single Source of Truth — the Solution-Architect Review Contract

**The substance of a complete solution doc is the contract the `dev:solution-architect` agent reviews against.** That
agent (dispatched in Phase 5) checks: driving outcome, scope and non-goals, business case / user-journey coverage
end-to-end (trigger, actor, happy path, acceptance criteria, business rules, edge cases, materials, inter-journey
dependencies), NFRs with data volume + growth, reuse-vs-build calls, integration intent (functional, not tech),
stakeholder map (incl. the Client Technical POC), rollout/migration/enablement, and **alignment with the solution
document's Decision Records**. Shape the doc so every one of those dimensions is answered or explicitly flagged as a
gap. This skill describes the *process* (how to gather, when to checkpoint, how to publish); the dimensions above are
the *substance*.

<HARD-GATE>
Do NOT start drafting any solution content until you have: (a) gathered the architecture baseline and every
product/business dimension named above, and (b) had the user approve the outline. Do NOT assume anything that needs a
domain answer — deployment model, hosting, multi-tenancy meaning, naming, integration details, journey shape — ask.
If a linked architecture doc is provided, read it in full and ground every alignment claim in it; do not paraphrase
from memory.
</HARD-GATE>

## Position in the Workflow

```
brainstorming  →  solution-doc (this skill)               →  /dev:plan
   (what)           (architecture baseline as DRs +            (tasks + story points)
                     for whom / why / what good looks like)
                              ↕
                          /dev:compare
                       (mid-draft decisions)
```

Output properties:
- **Self-contained** — readable without this conversation's context; the planner picks it up cold from Confluence.
- **Decision-aware** — every architecture choice and every mid-draft choice recorded as a **Decision Record** with a
  stable DR-ID, not as inline prose. Carried-forward DRs (from a linked architecture doc, if any) kept verbatim.
- **Plan-doc shape** — sections map to what `/dev:plan` consumes. Avoid task-level decomposition — that belongs in
  `/dev:plan`'s output.

## Phases

Complete in order. The cadence and gating below are this skill's responsibility; the substance is the
solution-architect review contract above.

### Phase 0: Design Readiness Check

Ask the user **at the start**, in a single message:

> Is the design settled enough to document, or should we brainstorm it first?
> - **Settled** — proceed. I'll capture the architecture baseline (deployment, stack, integrations, data model, auth)
>   as Decision Records during context-gathering, then shape the solution.
> - **Brainstorm first** — the *what* is still fuzzy. I'll stop so you can run a brainstorming pass first (e.g. the
>   `superpowers` plugin's `brainstorming` skill, if installed); the solution doc reads much better once the shape is
>   agreed.
> - **A separate architecture doc already exists** — paste the path, link, or contents. I'll read it in full, carry
>   its Decision Records forward verbatim, and treat it as the linked baseline.

Handling:
- **Settled:** proceed to Phase 1. The architecture baseline becomes the first block of context-gathering and is
  recorded as Decision Records (see Phase 1, dimension 0).
- **Brainstorm first:** stop. Point the user at a brainstorming pass. Do not draft.
- **Linked architecture doc:** read it in full. Extract and quote (a) hard constraints, (b) Decision Records, (c)
  Blockers & Open Questions. Carry the DRs forward without re-litigation or renumbering.

### Phase 1: Gather Context

Walk every dimension **one topic per message**, multiple-choice where possible, confirming each before moving on:

0. **Architecture baseline** (hard constraints — the absorbed architecture pass). Establish the non-negotiable facts
   *before* product shape, one topic per message:
   - **Deployment target** — where does this run? (Do not assume cloud provider, hosting model, or orchestration.)
   - **Tech-stack boundaries** — what's already chosen and locked in? (frameworks, runtimes, languages, datastores).
   - **Integration points** — what external systems does this touch? What are their APIs/protocols?
   - **Auth model** — who owns identity? How are permissions structured?
   - **Data model** — read the actual schema before discussing data. Do not guess table or column names.

   Record each settled architecture choice as a **Decision Record** (see the Decision Record format below). These are
   the doc's foundation; downstream cites them by DR-ID.
1. Business outcome & scope (IN / OUT, non-goals)
2. Use case & journey shape (per journey: trigger, actor, happy path, outcome, acceptance criteria, business rules,
   edge cases, materials, depends-on)
3. Acceptance, success & non-functional (incl. data volume + growth projection)
4. **Reusable-Components Survey** (Explore sub-agent — see below) → then reuse vs build & integration intent
5. Stakeholders (incl. Client Technical POC), rollout, migration & enablement
6. Architecture alignment (cross-check journeys against the baseline DRs from dimension 0)
7. Open questions, blockers, spikes/POCs needed

**Anti-pattern:** never ask all dimensions in one message. One topic per message. Confirm before proceeding. If a
journey requires a choice the baseline didn't face, follow the Decision Checkpoint pattern below.

#### Reusable-Components Survey (Explore Sub-Agent)

**Why a sub-agent:** mapping each new capability to either "reuse component X" or "build new" requires reading many
existing components to find the few that fit. The raw output (file lists, component summaries, near-misses) is large
and one-shot — keeping it out of the main context preserves room for the drafting that follows.

**When:** as the first step of dimension 4, after journeys are enumerated (dimension 2) and NFRs locked (dimension 3)
— without journeys you don't know what capabilities to search for; without NFRs you can't tell whether an existing
component meets the bar.

**How:** dispatch a single `Explore` sub-agent (`subagent_type: "Explore"`) with **thoroughness "medium"** by default
(or "very thorough" if the work spans multiple bounded contexts). Hand it:

1. The **list of capabilities** each journey requires (extracted from the per-journey happy paths) — e.g.
   "notification delivery", "contact upsert to an external service", "document export", "rate-limited webhook retry".
2. The **NFRs** captured in dimension 3 (volume, latency, retention) so the survey can flag components that don't meet
   the bar.
3. The **architecture-baseline constraints** (stack, deployment, integrations) so the search is scoped to the actual
   codebase.
4. An explicit request for a **short report** covering, per capability:
   - **Reuse candidate(s)** — component/service/package name, file path, brief description, current usage.
   - **Fit assessment** — meets NFRs (yes/no/unclear), aligned with architecture constraints (yes/no), known limits.
   - **Verdict suggestion** — `reuse` / `extend` / `build new` / `needs spike` — with one-line rationale.
   - **Notable near-misses** — components that look applicable but aren't, with why.
5. A length cap on the report (e.g. "under 500 words, table format where possible").

**Anti-pattern:** do not dispatch before journeys (dimension 2) and NFRs (dimension 3) are gathered. An unscoped
search returns noise and burns the agent.

**Using the result:** present the survey as the starting point for the reuse-vs-build conversation. The user decides
per capability; record each in the **Reuse vs build map** section, citing the file path the agent surfaced. A
`needs spike` verdict becomes an entry in **Spikes / POCs Needed**, not a silent assumption. If the survey reveals a
baseline constraint is impossible to satisfy with anything in the codebase, that is a new Decision Record (or an Open
Question) — record it, don't paper over it.

### Phase 2: Propose Outline

Present a section outline with 1-2 sentence scope per section. Include:
- Explicit IN / OUT scope summary
- Numbered journey list (J1, J2, …) with one-line summaries
- Any assumptions you're making (so the user can catch wrong ones early)

**Wait for approval.** Do not draft until the user confirms.

Default section order (adapt as needed):

1. Summary & driving outcome
2. Scope & non-goals
3. Target audience & roles
4. Architecture baseline (hard constraints captured in Phase 1, dimension 0)
5. Decision Records (architecture DRs + any carried forward from a linked doc, verbatim)
6. Business cases / user journeys (one subsection per journey)
7. Inter-journey dependency map
8. Non-functional requirements (incl. data volume + growth)
9. Success metrics & instrumentation
10. Reuse vs build map
11. Integration intent (functional)
12. Stakeholder map (RACI-style, incl. Client Technical POC)
13. Rollout, migration & enablement
14. New Decision Records (introduced at solution-doc level)
15. Blockers, Open Questions & Spikes/POCs Needed

### Phase 3: Draft Section-by-Section

Write ONE section (or one journey) at a time. After each:

1. Present it.
2. Flag any assumptions or decisions made within it.
3. Ask: "Does this section look right, or should I revise before moving on?"
4. Only proceed after approval.

Drafting rules:
- Reference actual code, config, schema, and recorded Decision Records — not hypothetical structures.
- Use `[CONFIRM: ...]` markers rather than guessing.
- Keep journeys product-level, not implementation-level (no payload shapes, no exact endpoint paths, no exact field
  types — those belong to the plan).
- Each journey is independently scannable — the planner reads them one-by-one.

#### Decision Record format

Record every architecture choice (Phase 1, dimension 0) and every mid-draft choice as a block with a stable ID:

```
### DR-<NNN>: <what was decided>
- **Options considered:** <A, B, C>
- **Chosen:** <X>
- **Why:** <constraint-grounded reasoning>
- **Trade-offs:** <what we're giving up>
- **Revisit when:** <conditions that would flip this>
```

**ID allocation rules:**

- IDs are assigned **sequentially in the order decisions are recorded** (`DR-001`, `DR-002`, …), starting with the
  architecture-baseline decisions.
- **Carried-forward DRs** from a linked architecture doc keep their original IDs verbatim. Do not renumber or rewrite
  the block — copy it as-is into the Decision Records section. New solution-doc DRs continue the sequence from the
  highest carried-forward ID.
- IDs are never reused, never renumbered. Retracted DRs stay in the doc as `~~DR-NNN (retracted)~~` with the reason.
- Downstream (`/dev:plan`, the `dev:solution-architect` review) cites by ID — renumbering breaks citations.

#### Decision Checkpoint (mid-draft)

If a real choice between viable options shows up (e.g. "notify via email or in-app?", "store snapshot or recompute?",
"reuse old endpoint or add new one?", "sync vs. async write path?"):

1. **Pause drafting.** Do not silently pick one.
2. **Offer to invoke `/dev:compare`** — hand it the context already gathered (baseline constraints, journeys touching
   this decision, reuse-vs-build implications) so it skips its own constraint phase. Also pass the candidate options.
3. **After `/dev:compare` returns**, record it as a **Decision Record** using the format above.

If the user prefers to settle quickly without invoking `/dev:compare`, still record it as a Decision Record with an
ID — just with a shorter rationale.

### Phase 4: Surface Blockers & Unresolved Topics

Before review, explicitly surface anything that could stall implementation or needs a decision from outside this
conversation. For each: **what it is**, **why it's unresolved** (what's missing / who must weigh in), **impact** if
left open, **suggested next step**. Put these in the dedicated **Blockers, Open Questions & Spikes/POCs Needed**
section — never buried inside other sections.

### Phase 5: Independent Review (Sub-Agent)

Before publishing, dispatch the **`dev:solution-architect`** sub-agent to review the draft. The drafter
self-auditing is weak — independent eyes catch what the drafter normalized.

**How:** Use the Agent tool with `subagent_type: "dev:solution-architect"`. The agent's persona is baked into its
definition, so do NOT load any persona file yourself.

Pass to the agent:

1. The full draft solution doc (path or contents).
2. The linked architecture doc, if one exists (path or contents) — so it can cross-check Decision Records are carried
   forward verbatim and no constraint is violated.
3. Instruction to return its structured **Solution Document Review** (Solution Shape Check, Journey Coverage Matrix,
   Critical Issues, Recommendations, Approved, Architecture Alignment, Gaps & Open Questions).

**After the agent returns**, present its review to the user. For each Critical Issue and Recommendation, decide
together: fix in-place, move to **Blockers & Open Questions** with an owner, or defer (record as Out-of-Scope with
rationale). Do NOT silently fill gaps. Do NOT auto-fold reviewer output — the user decides per item.

If a Critical Issue exposes a contradiction in the recorded Decision Records (e.g. a journey contradicts a baseline
DR, or a referenced DR-ID has no matching block), resolve it **as a Decision Record** — amend the affected DR or
allocate a fresh DR-ID for the new decision — or surface it as an Open Question. Do not patch around it in prose.

### Phase 6: Publish to Confluence

After review fixes are approved:

1. Ask the user for the **parent Confluence page** (URL or ID) and the **page title** (default: `<Feature Name> —
   Solution Document`).
2. Use `mcp__atlassian__createConfluencePage` to create the page under that parent. If the user asks to update an
   existing page, use `mcp__atlassian__updateConfluencePage` instead and keep the existing title/parent.
3. Return the **page URL and page ID** so the user can hand the ID directly to `/dev:plan <pageId>`.

If the user prefers not to publish (e.g. early draft, internal review only), offer to save the doc to a local path
instead and ask where.

## Key Principles

- **One design artifact** — the architecture baseline lives here as Decision Records; there is no separate
  architecture doc to keep in sync.
- **Ask, don't assume** — every dimension above is a place where assumption is forbidden, especially deployment,
  naming, and vendor conventions.
- **One topic / section at a time** — incremental approval prevents large rewrites.
- **Ground in reality** — read actual code, schema, and config before writing about them.
- **Decisions are records, not prose** — every choice gets a DR-ID; downstream cites by ID, so IDs never move.
- **Flag uncertainty** — `[CONFIRM: ...]` markers and Open Questions beat confident wrong assumptions.
- **Plan-doc shape, not implementation detail** — the planner needs the *what* and *why*; the *how* is its job.
