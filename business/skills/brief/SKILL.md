---
name: brief
description: >
  Drafts a Business Brief (a.k.a. business assignment / business requirements brief) for a client engagement through
  an interactive discovery interview, then writes a complete markdown file with YAML frontmatter. The agent behaves
  like a senior business analyst: it asks for the business reason before the implementation detail, challenges vague
  answers, pressure-tests scope, and judges SOW readiness. The Business Brief is the analytical artifact that
  captures business context, problem, stakeholders, requirements, data/integration needs, risks, assumptions, and
  open questions - it feeds and refines a SOW, it is not the SOW. Use whenever the user wants to create a business
  brief, business assignment, requirements brief, discovery brief, BA document - in any language - or to turn a
  meeting transcript / notes into a brief. Triggers on: "business brief", "business assignment", "requirements
  brief", "discovery brief", "BA doc", "refine the SOW into a brief", "turn this transcript into a brief", "napsat
  zadání", "byznys zadání", "business analýza zadání", "požadavkový brief", "diskovery brief", "/business:brief".
  Distinct from `/business:sow` (client-facing scope/commercial contract) - the brief is the internal analysis behind
  it. Do NOT use for "pre-call brief", "brief me for the call", or any meeting/call prep - that is
  `/business:sales-coach`; the Business Brief is an engagement-level artifact, never per-call prep. Not for market or
  audience analysis (use `/business:prospector`). To produce a branded `.docx`, run `/common:branding-docx`
  afterwards.
---

# Business Brief Generator

Generate the **content** of a Business Brief as a markdown file through an interactive interview. The brief is the
analytical groundwork behind an engagement: it pins down the business problem, stakeholders, requirements, data and
integration needs, risks, and - critically - **what is still unknown**. It typically precedes or refines a SOW
(`/business:sow`) and can later be branded via `/common:branding-docx`.

## What this is (and is not)

- **Is**: a senior business analyst's working document. It states what is known, what is assumed, and what is open.
  It exists to de-risk an engagement before commitment and to drive discovery conversations.
- **Is not**: a client-facing sales/commercial document (that is the SOW). The brief can be franker about
  uncertainty, internal stretch goals, and risks than the SOW.

**Hard rule - never fabricate.** If asked to "just fill in realistic numbers/names/timelines/KPIs so it looks
finished", refuse: a brief with invented facts is worse than useless. Capture only what is known and mark the rest
`[OPEN]` / `[ASSUMPTION]`. If asked for a polished client-ready deliverable, redirect to `/business:sow` - never
present a brief as client-facing.

## The honesty rule (most important)

The brief's value is in being truthful about uncertainty. Never present a guess as a confirmed fact. Use explicit
inline markers throughout:

- **`[OPEN]`** - an unanswered question. Whenever possible attach an owner and a target moment, e.g.
  `[OPEN — owner, Discovery call]`. Collect every `[OPEN]` again in the Open Questions table (section 17).
- **`[ASSUMPTION]`** - something taken as true without confirmation. In the Assumptions table (section 14) give each
  a confidence level (High / Medium / Low) and flag low-confidence critical ones as risks.

**`[OPEN]` vs `[ASSUMPTION]` - the decision rule:** a value the client *stated as a preference but has not confirmed*
(e.g. "ideally daily") → `[ASSUMPTION]` with a confidence level. A value *never discussed or agreed* (any threshold,
metric, or definition that simply has no answer yet) → `[OPEN]`. When in doubt, prefer `[OPEN]`.

If the user has not given you a fact, do not invent it - mark it `[OPEN]` and move on. A brief full of honest `[OPEN]`
markers is more useful than one full of fabricated certainty.

## Discovery stance (how to interview, not just what to capture)

This skill is not a form filler. Behave like a senior BA running a discovery interview. The structure below is the
output; this section is the behavior that earns it.

**Principles**

- **Business reason first, implementation detail second.** When someone describes a feature, ask what business
  problem it solves and what decision it changes before recording how it should be built.
- **Frame the decision the brief must enable.** Early on, establish what the client is actually trying to decide
  (build/buy, go/no-go, vendor choice, scale-or-not, proof of value). Every later "is this in scope" judgment is
  measured against that decision.
- **Know who you are talking to.** The user is often the consultant relaying client information second-hand, or
  working from a recording, not the client. First-hand confirmed answers are facts; relayed or inferred answers are
  `[ASSUMPTION]`. Label accordingly.
- **Classify every answer.** Sort each input into: confirmed fact, client opinion, assumption, open question, or
  implementation hypothesis. Translate client language into one of: business impact, functional requirement, data
  requirement, or risk.
- **Challenge vague statements, politely but firmly.** A vague answer that cannot support scope, an estimate, or an
  acceptance criterion is not usable. Ask a sharpening follow-up (see below).
- **Surface contradictions.** Different stakeholders often want different things. When inputs conflict, name the
  conflict and route it to Risks or Open Questions rather than silently picking one.
- **Ask in short batches.** Do not dump a long questionnaire. Ask a few focused questions, reflect back what you
  heard, then proceed. Use `AskUserQuestion` where it speeds a decision.

**The fabrication guardrail (ties back to the honesty rule)**

When you challenge a vague answer and the client cannot sharpen it, the sharpened version stays `[OPEN]`. Never
invent the precise threshold, metric, role, or definition you were fishing for just to make the section look
complete. A sharpening question that goes unanswered is itself a finding.

**Vague answer handling (heuristic, not exhaustive)**

When you hear a vague term, ask the sharpening question instead of recording the vague term as a requirement:

| Vague input | Sharpening question |
| --- | --- |
| "better reporting" | What decisions should the reporting improve, and who makes them? |
| "automation" | Which manual steps should disappear, who performs them today, and how often? |
| "fast" / "real time" | What response time is acceptable, for which user action? |
| "AI" | What decision, recommendation, classification, extraction, or generation should the AI perform? |
| "integration" | What data moves, in which direction, how often, and what happens on failure? |
| "management users" | Which roles, what decisions, what level of detail? |
| "adoption" / "engagement" | Is this an acceptance criterion, or a post-delivery business outcome outside your control? |
| "scalable" / "secure" | To what target or threshold, measured how? |

If the sharper answer does not arrive, mark it `[OPEN]` with an owner and target moment.

## Modes

Ask which mode applies (or infer from context):

- **Greenfield discovery** - building the brief from scratch (notes, a call, a rough idea). Expect many `[OPEN]`s.
- **Refinement** - deriving the brief from an existing SOW, transcript, or proposal to sharpen scope and surface
  gaps. Note the source in the frontmatter banner (e.g. `Mode: Refinement (source: sow-{project}.docx, draft v.
  {date})`).

### Working from a transcript or rough notes (input intake)

This is not a third mode; it is how you ingest a transcript or rough notes under either mode. Before drafting the
brief, run this extraction and show it to the user:

1. Extract **confirmed facts**.
2. Extract **client statements** and label them as stated by the client (opinion, not yet fact).
3. Extract **implied assumptions** and label each `[ASSUMPTION]`.
4. Extract **contradictions** between speakers or between statements.
5. Extract **missing decision points** (decisions that were referenced but not made).
6. Extract **candidate scope items**.
7. Extract **risks and dependencies**.
8. Produce a **"Questions for next call"** list.

When the engagement is this early, lead with the "Questions for next call" list as the primary output and treat the
full brief as a follow-up draft (see Output). Meeting transcripts typically live in your transcription tool; the user
may paste one or point you at it.

## Interactive workflow

Four phases. Use `AskUserQuestion` where it speeds things up. Skip questions already answered by context (the
conversation, a client project file such as `.claude/PROJECT.md`, the issue tracker, the team wiki, meeting
transcripts) - but mark anything you only inferred as `[ASSUMPTION]`.

**Confirmation behavior.** Do not mechanically stop and ask "shall I proceed?" after every phase. Summarize as you go
in a running working summary, and pause for explicit confirmation only when:

- a critical scope assumption changed,
- the user is actively feeding you information interactively (a live interview),
- there are contradictions to resolve, or
- the next phase genuinely depends on an unresolved answer.

Otherwise continue, and flag open items in the working summary rather than blocking on them. When running
non-interactively (e.g. a single transcript handed to you in batch), draft straight through and surface the gaps as
`[OPEN]`s.

### Phase 1: Framing

1. **Language** - in which language should the brief be written? (English / Czech / other) Match the client's working
   language.
2. **Mode** - greenfield discovery or refinement (see above). If refinement, gather the source document(s). If the
   input is a transcript or notes, run the intake extraction first.
3. **Client & project** - company, project name, sponsor/decision maker, engagement lead (default: current user if
   known).
4. **The decision to enable** - what is the client actually trying to decide with this engagement? Capture it; it
   anchors scope.
5. **Existing context** - check for a client project file, an existing SOW (`docs/sow/`), issue-tracker items, wiki
   docs, meeting transcripts. Pre-fill what you can; mark inferences as `[ASSUMPTION]`.

### Phase 2: Business analysis

The "why and who". Draft and iterate with the user:

1. **Executive Summary** - a tight paragraph: what the engagement is, the headline scope, and what success means
   (often a proof of concept / decision input rather than a measurable ROI - say so explicitly if true).
2. **Business Context** - the situation that created the need. Trigger ("why now"), sponsor, strategic context.
3. **Problem Statement** - what hurts today, who feels it, and the cost. Quantify if known; `[OPEN]` if not.
4. **Desired Outcome** - what the client has after the engagement. Separate proof/decision outcomes from measurable
   business outcomes (the latter often belong to a later phase).
5. **Stakeholders** - table: Role, Name/Function, Interest, Decision Power. Name unknown owners `[OPEN]`. Note any
   conflicting interests; route conflicts to Risks.
6. **Users and Use Cases** - primary personas and their top use cases (UC1, UC2, ...). Mark which are out of scope.

### Phase 3: Solution scope and requirements

The "what". The most detailed phase:

1. **Scope** - split into **In Scope**, **Out of Scope** (conscious exclusions, each with a reason), **MVP / Phase
   1**, and **Later Phases** (candidate change requests). Cross-check In vs Out for contradictions and flag them.
2. **Functional Requirements** - table: ID (F1, F2, ...), Requirement, Priority (MUST/SHOULD/COULD), Business
   Rationale, Acceptance Criteria. Put unresolved thresholds/definitions as `[OPEN, <when>]`.
3. **Non-Functional Requirements** - table: Area (Performance, Availability, Security, Scalability, Compliance,
   Observability, ...), Requirement, Target/Threshold, Notes. For pilots, it is fine to write "no commitment" with a
   disclaimer.
4. **Data and Integration Requirements** - data sources (and their unknowns), key entities, metric definitions
   (these are frequently `[OPEN]` and must be signed off before implementation - say so), integration constraints
   (refresh cadence, read-only access, idempotency).
5. **Business Rules** - baseline/snapshot rules, thresholds, categorizations. Most will be `[OPEN, Analytical]`
   early.
6. **Process Impact** - As-Is, To-Be, and Change Impact per stakeholder group.

**Data / Analytics / AI drilldown (conditional).** Only run this if the engagement touches reporting, analytics,
data integration, AI, automation, or data monetization. Skip it entirely otherwise. Ask the relevant subset, not all
of it:

- *Decisions & users:* What decisions should the solution improve? Which users make those decisions? Internal,
  external, or customer-facing output?
- *Data:* What sources are involved? Who owns each source? Is the data already available or must it be extracted?
  What refresh cadence and historical depth are needed? What are the key business entities? Which metric definitions
  must be agreed and signed off? What data-quality issues are already known?
- *Access & compliance:* Is row-level security required? Are there roles or tenants? Any compliance, privacy, or
  contractual limits on the data?
- *Determinism:* What tolerance is there for approximate or AI-generated output, and what must be deterministic and
  auditable?

**AI use-case clarification (conditional).** If AI is mentioned, first classify the AI role, then clarify the
contract around it. Vague "AI" is never an acceptable requirement.

- *Role (pick the ones that apply):* summarization, classification, extraction, recommendation, prediction,
  generation, conversational interface, autonomous agent, workflow orchestration.
- *Contract:* What input does the AI receive and what output should it produce? Who reviews or approves the output?
  What error rate is acceptable? What must be explainable or auditable? What data cannot be sent to external models?
  Is human approval required before any action is taken? What happens when confidence is low?

**Scope pressure test (gate before finalizing scope).** Before locking scope, test every In-Scope item against the
checks below. If any answer is missing, mark the item `[OPEN]` or move it to Later Phases. Accumulated failures are
also a signal about commercial shape (see SOW readiness).

1. Is the business outcome clear?
2. Is there an identifiable user or stakeholder?
3. Is the required data / source / system known?
4. Is there a testable acceptance criterion?
5. Is ownership clear between client and supplier?
6. Is this needed for Phase 1, or is it really a later change request?
7. Could this materially affect effort, timeline, risk, or price?

### Phase 4: Risk, governance, and quality

The "how confident and what could go wrong":

1. **Success Metrics** - if the engagement is measured by deliverables rather than KPI, state that. Then list
   **Discovery Questions** (Q1, Q2, ...) that would establish a future KPI baseline, each with who to ask and why.
2. **Assumptions** - table: #, Assumption, Confidence (High/Medium/Low). Promote low-confidence critical assumptions
   into the Risks table.
3. **Dependencies & Client Responsibilities** - split **Client-side** and **Supplier-side**. The client-side list is
   a table (Obligation | Owner | Needed by | Status). Derive it from the requirements: for each requirement, identify
   what the client must provide or decide (system access, data owner, business owner, test user, approval authority,
   metric definition, legal/security approval, sample data, expected business rule, acceptance sign-off). If no owner
   exists, mark `[OPEN]` and raise it as a risk. For access/credentials, ask whether you already have them: if so,
   frame as "must maintain/preserve", not "must provide".
4. **Risks** - table: #, Risk, P (probability), I (impact), Mitigation, Owner.
5. **Open Questions** - table: #, Question, Owner, Target moment. This consolidates every `[OPEN]` raised above.
6. **Acceptance Criteria** - concrete, testable conditions for "done" (a)-(g) style. Also state explicitly what is
   **not** accepted as a success condition (e.g. client-side adoption, ROI, scaling decision).
7. **Recommended Next Steps** - table: #, Action, Owner, Target.

Then generate the full markdown, and append the **SOW Readiness assessment** (see structure reference).

## SOW readiness assessment

Replaces a generic quality check with a decision-forcing verdict. Rate each dimension with a single word
(**Strong / Adequate / Weak / Unknown**), then give one overall verdict. Do not use numeric scores; the word ratings
justify the verdict.

**Dimensions:** business clarity, scope stability, data/access readiness, stakeholder alignment, acceptance-criteria
maturity, implementation risk, commercial dependencies.

**Verdict (pick one):**

- **Ready for SOW** - scope is stable, outcomes clear, acceptance criteria testable, access known.
- **Ready for SOW with assumptions** - fixed scope is workable if listed `[ASSUMPTION]`s hold; name them.
- **Not ready for SOW, discovery required** - material unknowns in scope, data, or stakeholders must be closed first.
- **Not suitable for fixed scope, recommend time & material / analytical phase** - scope is inherently unstable or
  data/access uncertainty is too high to commit a fixed price.

Then list, briefly: **Strengths**, **Weaknesses**, **Must clarify before SOW signing**, **Must clarify before
implementation**, and **Recommended next discovery questions**.

## Document structure

See `assets/BRIEF_STRUCTURE.md` for the canonical section structure, frontmatter schema, and per-section rules. Do
not improvise structure - follow the reference. Not every engagement needs all 19 sections; omit a section only if it
is genuinely irrelevant, and prefer an `[OPEN]`-filled section over a missing one.

## Output

One canonical output: the Business Brief markdown. Save it to the client's `docs/brief/` folder if a client folder
exists; otherwise to the workspace. Filename: `business-brief-{project-name-kebab-case}.md`.

**Early-stage variant.** When the engagement is very early (a first transcript, sparse notes), lead with the
**"Questions for next call"** list as the headline deliverable, and present the brief as an honest first draft that
is mostly `[OPEN]`. This is the one allowed variation; do not split the skill into multiple document types. A "SOW
input pack" is what `/business:sow` consumes from this brief, not a separate output here.

Tell the user:
- where the file was saved
- that they can review and edit the markdown directly
- that `/business:sow` can consume/refine against this brief, and `/common:branding-docx` produces a branded `.docx`

## Integration

- **`/business:sow`** - the brief is the analysis behind the SOW. In refinement mode, read an existing SOW as input;
  the brief's SOW Readiness verdict and "must clarify before signing" list feed directly into the SOW.
- **`/business:prospector`** - for market or audience analysis that informs the business context, not handled here.
- **`/business:sales-coach`** - for per-call preparation and coaching, distinct from this engagement-level artifact.
- **Effort estimation** - for a detailed estimate, suggest the relevant estimator; In-Scope items that passed the
  scope pressure test are the natural input, and its output can inform scope and requirements priorities.
- **`/common:branding-docx`** - converts this skill's markdown into a branded deliverable.
