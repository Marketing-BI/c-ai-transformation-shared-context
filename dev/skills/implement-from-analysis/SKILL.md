---
name: implement-from-analysis
description: |
  Use when the user has an approved plan from /dev:analyze-jira-ticket (or an equivalent hand-written plan) and
  wants to implement it. Orchestrates a disciplined plan → test-first (red/green) → implement → verify workflow
  while the user stays in the driver's seat for approvals and course corrections. At the end delegates to
  /dev:code-review for the parallel reviewer-agent dispatch, triage, and user-gated fixes. Creates LOCAL commits
  via /common:git-commit. **Never pushes to the remote and never opens a pull/merge request** — push and PR/MR
  are user decisions, done manually after review. Expects a plan as input — will not invent one.

  English triggers: "implement this plan", "implement from analysis", "implement PROJ-123", "proceed with
  implementation", "build out the approved plan", "/dev:implement-from-analysis"

  České spouštěče: "implementuj tento plán", "implementuj podle analýzy", "implementuj PROJ-123", "pokračuj
  s implementací", "naimplementuj schválený plán", "/dev:implement-from-analysis"

  Do NOT apply when: no plan exists yet (use /dev:analyze-jira-ticket first), the user only wants to read the
  ticket (use /common:read-jira-ticket), or the user wants a pure review of someone else's changes (use
  /dev:code-review or dispatch a reviewer agent directly).
---

# Implement from Analysis

Execute an approved implementation plan with the user, applying a disciplined test-first workflow and delegating
post-implementation review to `/dev:code-review`. This skill is the orchestrator — it does not re-analyse, does not
re-plan, and does not proceed without approval at every major checkpoint.

> **Optional enhancement:** if the `superpowers` plugin is installed, you can lean on its skills (`writing-plans`,
> `test-driven-development`, `subagent-driven-development`, `verification-before-completion`) to drive each step.
> They are an enhancement, not a requirement — this skill describes the same discipline in its own words so it is
> fully self-contained without them.

## Precondition

The user must arrive with:

- A ticket key (for traceability)
- An approved plan — normally produced by `/dev:analyze-jira-ticket`, optionally attached in the prompt or
  referenced by file

If the plan is missing, stop and direct the user to run `/dev:analyze-jira-ticket` first. Do **not** invent a plan
from the ticket.

## When NOT to use

- No plan exists yet → `/dev:analyze-jira-ticket`.
- The user only wants to read the ticket without implementing → `/common:read-jira-ticket`.
- The user wants a pure review of someone else's changes → `/dev:code-review`, or dispatch a reviewer agent directly.

## Procedure

### 1. Confirm preconditions

Verify:
- Plan is present (show the user the plan you have and ask "is this the approved plan?")
- Working tree is clean or on a dedicated feature branch — if not, ask before proceeding
- The applicable convention/standard skills are loaded and the relevant conditional ones apply to the packages being
  changed

### 2. Worktree decision

Offer an isolated worktree if the change is large or the user wants isolation from their current workspace (a git
worktree, or `superpowers:using-git-worktrees` if that plugin is installed). For small changes, skip and work on the
current branch.

### 3. Refine the plan if needed

If the plan is high-level but implementation needs a concrete task breakdown, produce a step-by-step plan the user
can review — listing each task, the files/areas it touches, and the tests that will cover it. (You can use
`superpowers:writing-plans` for this if installed.)

If the plan is already step-by-step and approved, skip this.

### 4. Implement task by task (test-first: red → green)

For each task in the plan, follow a strict test-first loop (this is the core of test-driven development; use
`superpowers:test-driven-development` if installed):

1. **Red** — write the failing test(s) first. Show the user the test → get approval.
2. **Run** the test → confirm it fails for the right reason.
3. **Green** — implement the minimum code to pass → show the diff → get approval.
4. **Run** the test → confirm it passes.
5. **Refactor** if needed, keeping tests green → show the diff → get approval.
6. **Commit boundary** — propose a logical commit point; the user decides when to actually commit.

When a task is complex or has independent subparts, split the work into focused sub-tasks (delegate to
`superpowers:subagent-driven-development` if installed, otherwise sequence them yourself).

### 5. Enforce project rules during implementation

The applicable convention/standard skills are in context. When writing code, honour the universal principles they
encode — for example:

- Strong typing and safe contracts at boundaries; no escape hatches that defeat the type/contract system.
- Validate and parse all input at system boundaries before trusting it.
- Layer discipline: transport → application/service → data-access. Keep business logic out of the transport layer.
- Stateless services (no in-memory caches or mutable singletons that break horizontal scaling).
- No hardcoded magic values — shared constants live in a shared location.
- Wrap third-party libraries used across files behind a thin abstraction so they're swappable and testable.
- Never expose internal errors or stack traces to clients.
- Follow the repo's naming conventions consistently (files, types, functions, variables).

The project-scoped conditional skills (backend, database, frontend, docker, testing) provide further, stack-specific
constraints. Apply them wherever they intersect the change.

### 6. Surface choices, don't hide them

If a task has multiple reasonable approaches with trade-offs, state them and ask the user. Do not silently pick one.
Implementation is a conversation, not a monologue.

### 7. Code review — delegate to `/dev:code-review`

After all tasks are implemented and tests pass, invoke `/dev:code-review` (scope: `branch` or `uncommitted`, as
appropriate). `/dev:code-review` owns the parallel reviewer-agent dispatch (selecting agents by what actually
changed), the triage gate, and the user-gated fix loop — do not re-implement that logic here.

Pass a short context note so the reviewers know this is a post-implementation pass for `<TICKET-KEY>`.

### 8. Iterate on review findings

`/dev:code-review` drives the fix loop. For **Critical Issues** it will re-dispatch only the affected reviewer
for a second pass, agree fixes with you, and apply them. For **Recommendations** it will decide with you what to
address now vs. defer. This skill resumes after `/dev:code-review` reports its outcome.

### 9. Final verification

Run the project's verification commands (tests, lint, type/contract check, build) and confirm all green — capture the
real output. (Use `superpowers:verification-before-completion` if installed.) Do not declare the work done without
evidence.

### 10. Local commits only — NO push, NO PR/MR

Create commit messages via `/common:git-commit` (conventional commits, imperative mood, explain *why* not *what*).
If the change is multi-commit, group logically — never "wip" or "fix typo" commits on the main chain.

**Do not push to the remote. Do not run `git push`, `git push --force`, or any variant.** Commits stay local.

**Do not create a pull/merge request.** The user opens the PR/MR themselves when they are ready, after reviewing the
local commits.

### 11. Handoff

Announce completion clearly:
> "Implementation of `<TICKET-KEY>` complete. N local commits ready on branch `<branch>`. N critical review findings
> resolved, M recommendations deferred (tracked in <ticket>).
>
> Next steps (user's choice): review `git log`, then run `/dev:open-pr` when ready (or `/dev:open-pr prep-only`
> for just the pre-flight checklist), or push manually and open a PR/MR on your git host."

Stop. Do not push, do not open the PR/MR, do not auto-merge, do not close the ticket, do not move it in Jira. Those
are user decisions.

## Anti-patterns

- **Do not re-analyse.** If the plan is incomplete, ask the user to re-run `/dev:analyze-jira-ticket`, not recreate
  the analysis inline.
- **Do not invent a plan.** Require the plan as input. The ticket alone is not enough.
- **Do not batch changes past approval boundaries.** The user confirms diffs per task, not in bulk.
- **Do not skip reviewers to "save time".** Reviewer dispatch is the technical validation. Skipping it defeats the
  architecture.
- **Do not claim completion without verification.** Always run the verification commands; evidence before assertions.
- **Do not use commit-hook bypass flags** (e.g. `--no-verify`) or skip hooks to bypass failures. Investigate and fix.
- **Never push to the remote.** Commits stay local. If the user asks "push it", confirm explicitly before running
  `git push`; never push as a default step of this skill.
- **Never open a PR/MR automatically.** The user decides when to open it.
