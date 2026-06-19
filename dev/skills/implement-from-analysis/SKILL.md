---
name: implement-from-analysis
description: |
  Use when the user has an approved plan (or a context dump accepted as the working plan) (from /dev:analyze-jira-ticket,
  /dev:plan, a doc, a local file, or inline content) and wants it implemented as reviewed LOCAL commits. Confirms preconditions, asks you to choose one of four
  delivery models (A worktree / B current branch / C umbrella+stacked / D local-only), does the matching git setup,
  runs test-first TDD task-by-task with scope discipline, then delegates the review pass to /dev:code-review and runs
  final verification. Creates LOCAL commits via /common:git-commit. **Never pushes and never opens a PR/MR** — for
  models A/B/C the push + PR/MR is owned downstream by /dev:open-pr (invoked by /dev:develop or the user); model D
  stops locally. Expects a plan as input — will not invent one.

  English triggers: "implement this plan", "implement from analysis", "implement PROJ-123", "proceed with
  implementation", "build out the approved plan", "/dev:implement-from-analysis"

  České spouštěče: "implementuj tento plán", "implementuj podle analýzy", "implementuj PROJ-123", "pokračuj
  s implementací", "naimplementuj schválený plán", "/dev:implement-from-analysis"

  Do NOT apply when: no plan exists yet (use /dev:analyze-jira-ticket or /dev:plan first), the user only wants to read
  the ticket (use /common:read-jira-ticket), or the user wants a pure review of someone else's changes (use
  /dev:code-review).
---

# Implement from Analysis — delivery setup + implementation + local review

Take an approved plan to **reviewed local commits**. This skill owns the **delivery setup** (worktree, current
branch, or umbrella branch), **the implementation work** (test-first TDD per task with scope discipline), and the
**local review pass** (delegated to `/dev:code-review`). It deliberately stops at the end of verification — push and
PR/MR are user-gated downstream.

It is the orchestrator: it does not re-analyse, does not re-plan, and does not proceed without approval at every major
checkpoint.

Two caller paths:

- **User directly** — runs through to local commits and hands back. Default delivery model is **D (local-only)**
  unless the user picks A, B, or C.
- **`/dev:develop`** — invokes this for the doing phase of its full cycle. After this skill returns, develop reads the
  chosen model and either continues to push + PR/MR via `/dev:open-pr` (A, B, or C) or stops gracefully (D).

> **Optional enhancement:** if the `superpowers` plugin is installed, you can lean on its skills (`writing-plans`,
> `using-git-worktrees`, `test-driven-development`, `subagent-driven-development`, `verification-before-completion`)
> to drive each step. They are an enhancement, not a requirement — this skill describes the same discipline in its own
> words so it is fully self-contained without them.

## Precondition

The user (or calling skill) must arrive with an **approved plan + optional ticket key**. The plan can be:

- the output of `/dev:analyze-jira-ticket` (its structured context dump — sufficient for thin/clear changes)
- the output of `/dev:plan` (a heavyweight plan — for complex work)
- a doc authored manually
- a local markdown file
- inline content pasted into the prompt

If no plan is provided, **stop**. Do **not** fabricate one. Redirect:

- Ticket needs analysis first → `/dev:analyze-jira-ticket <KEY>` (then come back here)
- A solution doc needs a formal plan → `/dev:plan <doc>` (then come back here)
- Just need to read a ticket → `/common:read-jira-ticket`
- Want the full source → push → PR/MR cycle → `/dev:develop` (it delegates here for the doing phase, then continues
  with `/dev:open-pr` on top)

## When NOT to use

- No plan exists yet → `/dev:analyze-jira-ticket` or `/dev:plan`.
- The user only wants to read the ticket → `/common:read-jira-ticket`.
- Pure review of someone else's changes → `/dev:code-review`.
- Need the full source → PR/MR cycle → `/dev:develop`.

## Procedure

### Step 1 — Confirm preconditions

- Show the user the plan you have; ask **"is this the approved plan?"**
- Verify working-tree state (clean, or on a known feature branch) — if not, ask before proceeding.
- Confirm the always-on rules are loaded and the applicable conditional rules cover what the change touches.

### Step 2 — Delivery model (ask the user)

> "How do you want to deliver this work?
>
> **A) Single PR/MR via git worktree** — recommended for a cohesive feature (one logical chunk). New isolated
> worktree under `.worktrees/<branch>/`, one branch. Best when you have other work in-flight elsewhere and want full
> isolation.
>
> **B) Single PR/MR on the current branch (no worktree)** — same single-PR/MR outcome as A but implemented directly
> in the current workspace. Requires a **clean working tree**. If you're on the default branch, the skill will
> suggest creating a feature branch first. Best when you don't have other in-flight work and don't want a worktree
> dir to manage.
>
> **C) Multi-PR/MR split via umbrella branch** — recommended for larger work split across several PR/MRs. Umbrella
> `feature/<TICKET>` on the remote (one-time), sub-branches `feature/<TICKET>-<step>` per PR/MR, stacked.
>
> **D) Local-only on the current branch** — implement + review locally. No worktree, no umbrella, no push, no PR/MR.
> Default when this skill is invoked directly without a strict delivery target.
>
> Which model?"

The chosen model **becomes part of the result of this skill** alongside the commit count and branch info — callers
(`/dev:develop`) read it after handoff to decide whether to continue to push + PR/MR via `/dev:open-pr` (A, B, or C)
or stop (D).

If invoked directly by the user with no clear delivery target, default to **D (local-only)**. If invoked by
`/dev:develop`, all four options are valid — develop gracefully stops if D is chosen.

### Step 3 — Git setup based on the chosen model

See `references/conventions.md` for the full table of branch names, worktree paths, PR/MR base refs, and merge
direction per model — including first-time umbrella setup and the stacked-PR/MR retargeting flow.

- **Model A (worktree):** create a new git worktree under `.worktrees/<branch>/` (`git worktree add`, or
  `superpowers:using-git-worktrees` if installed) on branch `<TICKET>-<short-name>`.
- **Model B (current branch, no worktree):** verify a clean working tree (`git status` clean). If dirty, stop and ask
  the user to commit / stash first. If on the default branch, suggest creating and switching to a feature branch
  (`<TICKET>-<short-name>`). If already on a matching feature branch, reuse it.
- **Model C (umbrella, multi-PR/MR):** if the `feature/<TICKET>` umbrella branch doesn't yet exist on the remote, do
  the one-time umbrella setup. Then create the sub-branch from the umbrella (or stacked on the preceding sub-branch's
  head if it isn't merged yet).
- **Model D (local-only):** no worktree, no umbrella. Use the current branch as-is. If on the default branch and the
  plan is non-trivial, suggest a feature branch (`<TICKET>-<short-name>`) before continuing.

After branch setup, **run the test suite (or `build` + `lint` if no test runner)** to confirm a **clean baseline**
before implementation starts.

### Step 4 — Implement task by task (test-first: red → green)

Execute the plan task by task. Apply the **scope discipline** — *Think-before-coding / Simplicity-first /
Surgical-changes / Goal-driven execution* — from the always-on **practices** rule (`dev/rules/practices.md`).
Don't restate it here; honour it. The default is restraint, not expansion: touch only what the task requires, choose
the simplest solution that fully solves the problem, and stop when the stated goal is met.

For each task, follow a strict test-first loop (the core of test-driven development; use
`superpowers:test-driven-development` if installed):

1. **Red** — write the failing test(s) first.
2. **Run** the test → confirm it fails for the right reason.
3. **Green** — implement the minimum code to pass.
4. **Run** the test → confirm it passes.
5. **Refactor** if needed, keeping tests green.
6. **Commit boundary** — propose a logical commit point and create the commit via `/common:git-commit`.

When a task is complex or has independent subparts, split it into focused sub-tasks (delegate to
`superpowers:subagent-driven-development` if installed, otherwise sequence them yourself).

Implementation rules on top of the scope discipline:

- **TDD when a test runner exists:** failing test → minimum implementation → green → commit. Never write
  implementation before a test exists.
- **No test runner? Don't invent one** just for this task. Default: describe expected behaviour → implement →
  manually verify (explicit command + output check + visual check) → commit.
- **No new TODO/FIXME** in the code this task adds or changes. Existing TODOs in touched files are out of scope. Defer
  work via a plan-file task, not a code comment.
- **Don't break existing interfaces/contracts** without a documented reason.
- **Run the full test suite (or `build` + `lint` if no tests) after each task** before starting the next — this is the
  safety net.

The project's convention/standard rules (typing, layer discipline, boundary validation, naming, etc.) are auto-loaded
via the always-on and applicable conditional rules. Apply them wherever they intersect the change — don't restate them.

If a task corresponds to an existing tracker issue, you may transition its status — but **only with explicit user
confirmation in chat**.

### Step 5 — Surface choices, don't hide them

If a task has multiple reasonable approaches with trade-offs, state them and ask the user. Do not silently pick one.
Implementation is a conversation, not a monologue.

### Step 6 — Code review — delegate to `/dev:code-review`

After all tasks are implemented and the tests pass, **invoke `/dev:code-review`** for the local review pass. Resolve
the review scope from the chosen delivery model (typically `branch` for A/B/D-on-feature-branch, or the appropriate
diff range for C / D-on-default-branch). `/dev:code-review` owns the reviewer-agent dispatch (selecting agents by what
actually changed), the triage gate, and the user-gated fix loop — **do not** fan out reviewer agents from this skill.

Pass a short context note so the reviewers know this is a post-implementation pass for `<TICKET-KEY>`, including the
plan reference and the diff range that matches the delivery model.

### Step 7 — Iterate on review findings

`/dev:code-review` drives the fix loop. For **Critical Issues** it will re-dispatch only the affected reviewer for a
second pass, agree fixes with you, and apply them. For **Recommendations** it will decide with you what to address now
vs. defer. This skill resumes after `/dev:code-review` reports its outcome.

### Step 8 — Final verification

Run the project's verification commands (tests, lint, type/contract check, build) and confirm all green — capture the
real output. Evidence before assertions: do not declare the work done without it. (Use
`superpowers:verification-before-completion` if installed for the same discipline.) Do not use commit-hook bypass
flags (e.g. `--no-verify`) or skip hooks to get past failures — investigate and fix.

### Step 9 — Local commits only — NO push, NO PR/MR

Create commit messages via `/common:git-commit` (conventional commits, imperative mood, explain *why* not *what*). For
multi-commit work, group logically — never "wip" or "fix typo" commits on the main chain.

**Do not push to the remote. Do not run `git push`, `git push --force`, or any variant.** (Exception: Model C's
one-time umbrella setup pushes the empty umbrella branch so sub-PR/MR bases resolve — that is branch plumbing, not the
work itself.) The implementation commits stay local.

**Do not create a pull/merge request.** For models A/B/C the push + PR/MR is owned downstream by `/dev:open-pr`
(invoked by `/dev:develop` or the user). For model D, the user pushes manually when ready.

### Step 10 — Handoff

Announce completion to the caller (user or `/dev:develop`):

> "Implementation of `<TICKET-KEY>` complete on branch `<branch>` (delivery model **<A | B | C | D>**).
> - **N local commits** ready
> - **M critical review findings** resolved (commit hashes: `<list>`)
> - **K recommendations**: <fixed-now-list> / <deferred-to-tickets-list>
> - **Q open questions / client gaps** flagged (informational, for user resolution)
>
> Next:
> - If `/dev:develop` is the caller and the model is **A**, **B**, or **C**: it continues to push + PR/MR via
>   `/dev:open-pr`.
> - If the model is **D** or this skill was invoked directly: stop here. Review `git log`, then run `/dev:open-pr`
>   when ready (or `/dev:open-pr prep-only` for just the pre-flight checklist), or push manually and open the PR/MR on
>   your git host."

Stop. **No `git push` of the implementation work. No PR/MR. No tracker transition without explicit user
confirmation.** Push, PR/MR, and tracker moves are downstream — either user-led, or by the calling skill
(`/dev:develop` via `/dev:open-pr`).

## Anti-patterns

- **Don't re-analyse.** If the plan is too thin to implement, stop and send the user back to `/dev:analyze-jira-ticket`
  or `/dev:plan` — don't reconstruct the analysis inline.
- **Don't fabricate a plan.** The plan is required input; a ticket key alone is not enough.
- **Don't batch changes past approval boundaries.** Confirm logical commits per task, not in bulk.
- **Don't fan out reviewer agents here.** The review pass is delegated to `/dev:code-review` — it owns reviewer
  selection, triage, and the fix loop. Skipping or duplicating it defeats the consolidation.
- **Don't claim completion without verification.** Always run the verification commands; evidence before assertions.
- **Don't use commit-hook bypass flags** (e.g. `--no-verify`) or skip hooks to bypass failures. Investigate and fix.
- **Never push the implementation work** as a default step. If the user explicitly says "push it now", confirm in
  chat, then run — but never as a default.
- **Never open a PR/MR automatically.** PR/MR opening is downstream — `/dev:open-pr` (for A/B/C), or user-led.
- **Don't ignore the chosen model when scoping the review.** Wrong diff range = wrong findings.

## Decision tree (quick reference)

```
implement-from-analysis invoked
    │
    ▼
Step 1: confirm plan + working-tree state + rules loaded
        (if no plan → STOP, redirect to analyze-jira-ticket / plan)
    │
    ▼
Step 2: ask delivery model
    ├─ A → single PR/MR via worktree
    ├─ B → single PR/MR on current branch (no worktree)
    ├─ C → umbrella + stacked sub-branches (multi-PR/MR)
    └─ D → local-only on current branch (default for direct invocation)
    │
    ▼
Step 3: git setup per chosen model (references/conventions.md)
    └─ run baseline test/build/lint → must be clean
    │
    ▼
Step 4: implement task by task — test-first (red→green), scope discipline from practices
    └─ full test suite + lint after each task
        (Step 5 surfaces trade-offs inline during Step 4 — no separate branch)
    │
    ▼
Step 6: delegate review to /dev:code-review (scope by model)
    └─ Step 7: it drives the fix loop (Critical / Recommendations)
    │
    ▼
Step 8: final verification (evidence before assertions)
    │
    ▼
Step 9–10: local commits only → handoff
    └─ model A/B/C + caller = /dev:develop → continues to push + PR/MR via /dev:open-pr
    └─ model D OR invoked directly → stop here; push/PR/MR is user-led
```
