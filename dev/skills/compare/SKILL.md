---
name: compare
description: |
  Structured tech-decision comparison that evaluates options against your project's ACTUAL constraints — not generic
  pros/cons lists. Grounds the comparison in real code, config, and deployment facts before recommending, and ties
  every advantage or disadvantage to a specific constraint. Use when choosing between approaches, tools, patterns,
  frameworks, datastores, or migration strategies.

  English triggers: "compare these options", "which should we use", "evaluate the trade-offs", "X vs Y for this
  project", "help me choose between", "tech decision", "/dev:compare"

  České spouštěče: "porovnej možnosti", "co máme použít", "vyhodnoť kompromisy", "X vs Y pro tento projekt",
  "pomoz vybrat mezi", "technické rozhodnutí", "/dev:compare"
---

# Tech Decision Comparison

Produce structured, grounded comparisons for technical decisions — evaluated against the project's actual constraints,
not generic advice.

<HARD-GATE>
Do NOT present a comparison matrix until you have identified the project's actual constraints and confirmed them with
the user. Do NOT recommend based on general industry best practices — recommend based on what fits THIS project.
</HARD-GATE>

## Why This Skill Exists

Generic comparisons waste time because they evaluate options against constraints that don't apply (e.g. suggesting a
CDN-served static bundle when the project deploys as a long-running service, or recommending a rendering pattern that
conflicts with the existing embedding model). This skill forces grounding in real project context before comparing.

## Checklist

Complete these phases in order:

1. **Clarify the decision** — what exactly are we choosing between, and why now?
2. **Gather constraints** — what does the answer have to work with?
3. **Research options** — read actual code, docs, and config
4. **Build comparison matrix** — evaluate against real constraints
5. **Surface blockers & unknowns** — what could change the answer?
6. **Recommend** — with reasoning tied to constraints

## Phase 1: Clarify the Decision

Before researching anything, establish:

- **What's the decision?** — name the specific choice (e.g. "single-page app vs server-rendered for the portal", not
  "how to build the frontend").
- **What triggered it?** — why is this being evaluated now? (new requirement, pain point, migration, tech debt)
- **What are the candidate options?** — ask the user what they're considering. Don't invent options they haven't
  mentioned unless there's an obvious gap.
- **What does success look like?** — what outcome matters most? (speed to ship, performance, maintainability, team
  familiarity)

## Phase 2: Gather Constraints

Identify the non-negotiable facts that any option must work with.

**If invoked by another skill (e.g. `/dev:solution-doc`) that has already gathered constraints**, do NOT re-ask them
one at a time. Restate the passed constraints in a single message, ask the user to confirm or correct, and proceed
once confirmed. The caller is responsible for handing over: existing stack, deployment model, integration
requirements, team constraints, migration cost.

**If invoked standalone**, ask ONE AT A TIME:

- **Existing stack** — read actual code, manifests, dependency files, deployment configs. Do not assume.
- **Deployment model** — where and how does this ship? (Do not suggest deployment patterns that don't match.)
- **Integration requirements** — what external systems must this work with? Read existing integration code.
- **Team constraints** — who maintains this? What do they know? What's the timeline?
- **Migration cost** — is this greenfield or does it replace something? What's the switching cost?

For each constraint, state what you found/understand and confirm with the user.

## Phase 3: Research Options

For each candidate option:

- **Check the codebase** — delegate this to a subagent (preferably the `Explore` agent) to search for existing code,
  config, or patterns that favor or conflict with this option. Launch one Explore agent per option in parallel when
  possible. Provide the agent with the option name, the constraints from Phase 2, and ask it to report concrete file
  paths and snippets — not generic observations.
- **Check actual compatibility** — does this option work with the confirmed stack and deployment model?
- **Identify the real trade-offs** — not textbook pros/cons, but what specifically changes for THIS project.

Do NOT pad options with generic advantages. If an advantage doesn't matter given the constraints, leave it out.

## Phase 4: Build Comparison Matrix

Present a structured comparison with:

### Decision Criteria (derived from constraints)

List the criteria that actually matter for this decision, weighted by the user's stated priorities. Example:

| Criteria | Weight | Why it matters here |
|----------|--------|---------------------|
| Works with the confirmed deployment model | Must-have | Non-negotiable infrastructure |
| Supports the core embedding/integration requirement | Must-have | Core product feature |
| Migration effort from current setup | High | Team bandwidth is limited |
| Server-side rendering performance | Low | Internal dashboard, not a content site |

### Option Evaluation

For each option, evaluate against EACH criterion:

| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|
| ... | ... | ... | ... |

**Rules:**
- Every cell must reference something concrete (code, config, docs, or a confirmed constraint) — not "generally good
  at X".
- If you can't evaluate an option against a criterion, mark it `[UNKNOWN — needs: ...]`.
- If an option fails a must-have criterion, flag it immediately — don't bury it in the matrix.

## Phase 5: Blockers & Unknowns

Before recommending, explicitly list:

- **Unknowns that could change the answer** — information you don't have that might flip the recommendation.
- **Blockers per option** — things that would need to be resolved to proceed with each option.
- **Risks per option** — what could go wrong, specific to this project's context.

For each item include:
- What it is
- Why it matters for this decision
- How to resolve it (who to ask, what to test, what to read)

Do not skip this phase even if you feel confident. Surfacing unknowns prevents costly reversals.

## Phase 6: Recommend

Present your recommendation with:

1. **The pick** — which option and why, in 1-2 sentences.
2. **Constraint alignment** — how it satisfies the must-haves and scores on high-weight criteria.
3. **What you're giving up** — honest trade-offs of this choice vs the runner-up.
4. **When to reconsider** — under what conditions would the other option become better?

> **Invoked from `/dev:solution-doc`?** Return the recommendation in a shape that drops straight into a Decision
> Record block (options considered, chosen, why, trade-offs, revisit-when), so the caller can record it by DR-ID
> without restructuring.

## Key Principles

- **Ground in reality** — read code, config, and schemas before comparing. Do not evaluate based on assumptions.
- **Constraints over preferences** — must-haves eliminate options; preferences rank what's left.
- **No generic pros/cons** — every advantage or disadvantage must be tied to a specific project constraint.
- **Surface unknowns** — an honest "I don't know" is better than a confident wrong recommendation.
- **Respect the user's options** — compare what they're considering. Only add options if there's a clear gap, and
  explain why.
