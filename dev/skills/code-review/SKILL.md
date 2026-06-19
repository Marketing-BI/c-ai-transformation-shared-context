---
name: code-review
description: |
  Multi-agent QA / code review. Resolves a review scope (uncommitted changes by default, a branch diff, a path, the
  whole repo, or a generic PR/MR URL — host-agnostic), dispatches the relevant dev: reviewer agents in parallel,
  optionally exercises live endpoints, compiles and de-duplicates findings, runs them through a triage gate, drives
  user-gated fixes, and writes a triaged review report. Use when the user wants a thorough code review / QA pass
  before opening a PR/MR, or to review an existing one. Fixes are advisory and user-gated — the skill never fixes
  autonomously and never pushes or opens a PR/MR.

  English triggers: "code review", "QA this", "review my changes", "review my branch", "review this PR", "review
  this MR", "/dev:code-review"

  České spouštěče: "code review", "zkontroluj kód", "zreviewuj branch", "zreviewuj větev", "zreviewuj moje změny",
  "udělej QA", "zkontroluj tento PR", "/dev:code-review"

  Do NOT apply when: the user wants you to implement an approved plan (use /dev:implement-from-analysis) or only to
  read a ticket (use /common:read-jira-ticket).
user-invocable: true
argument-hint: '[scope: uncommitted | branch | <path> | all | <PR/MR-url>] [optional context file]'
allowed-tools:
  Read, Write, Glob, Grep, Bash, Agent, AskUserQuestion
effort: high
---

# Code Review & QA

Orchestrate the `dev` reviewer agents over a defined scope, triage what they find, fix the blockers with the user,
and leave a report. **Announce at start:** say you are starting the `/dev:code-review` QA pass.

Reviewers apply the org code-review standards — `/common:code-review-standards` — as the baseline; findings are
triaged against them.

The reviewer agents run outside this context and **read their own rules** (their agent definitions point them at the
relevant convention/standard skills) — you do not pre-load rules for them. Your job is orchestration: resolve scope,
dispatch the right reviewers, compile + triage, drive fixes, verify.

**Hard boundaries:** advisory + user-gated fixes only — never fix autonomously, never `git push`, never open a
PR/MR. Only the user decides those.

---

## Phase 0 — Resolve scope

Parse `$ARGUMENTS` as `[scope] [context-file]`. Determine `SCOPE_FILES` (the files to review) and `DIFF_RANGE` (the
git range to hand each agent):

| Scope arg | How to resolve | DIFF_RANGE |
| --- | --- | --- |
| _(none)_ → **uncommitted** | `git diff --name-only` + `git diff --cached --name-only` + `git ls-files --others --exclude-standard` | working tree |
| `branch` / `branch-diff` | base = default branch (`master`/`main`/`develop`); `git diff <base>...HEAD --name-only` | `<base>...HEAD` |
| `<path>` (a folder/service) | files under that path changed in the working tree or branch | as above, filtered to path |
| `all` / `monorepo` | the whole repo (state this is expensive and confirm) | — |
| `<PR/MR-url>` (bonus) | fetch the PR/MR diff via the host's CLI or API (see below) | the PR/MR's diff |

**PR/MR URL handling (host-agnostic).** Do not assume a specific git host or hardcode a vendor CLI. Obtain the diff
through whatever the user has wired up, in this order:

1. The user pastes the diff/patch directly into the prompt — review that.
2. The host's own CLI or MCP integration, if the client has configured one (this is the integration point the client
   wires to their git host) — use it to fetch the changed file list and the patch.
3. If neither is available, ask the user to provide the diff or check out the branch locally.

Review works on the fetched diff. Live testing (Phase 2) and fixes (Phase 5) need local code — so after the diff
review, **offer to check out the PR/MR branch locally**. If the user declines (or it can't be checked out), run
**review-only**: skip Phase 2 and Phase 5, still produce the report.

If a context file (e.g. a feature/solution doc) is passed or found, note it — pass its path to the
`dev:business-case-evaluator` if dispatched. If `SCOPE_FILES` is empty, stop and tell the user there's nothing to
review.

---

## Phase 1 — Parallel review

Pick reviewers by what `SCOPE_FILES` actually contains — **do not dispatch all of them blindly.** Load
`references/dispatch-matrix.md` and select the matching agents. Dispatch them **in parallel: a single message with
multiple `Agent` tool calls**, each with `subagent_type` set to the plugin-qualified `dev:` agent name.

Give every agent the same context block:

```
Review scope: <DIFF_RANGE or PR/MR diff>. Files in scope: <SCOPE_FILES>.
Review ONLY what this diff adds or changes. Read your own rules as your agent definition instructs.
Calibration: report only findings you are confident about; severity must be backed by evidence; ZERO findings is a
valid, expected outcome — do not invent problems. Return your standard Critical / Recommendations / Approved /
Out-of-scope structure.
```

For a PR/MR diff the agents can't open local files at the diff's commit — paste the patch into their prompt.

---

## Phase 2 — Live endpoint testing (skip gracefully if not runnable)

Only for local scopes (or a checked-out PR/MR) that touch a runnable API surface. Load `references/live-testing.md`
and follow it: detect the dev/start command, start the app, discover the in-scope endpoints, exercise happy /
validation / authz / error / edge paths, capture failures as findings, then **kill every process you started**.

If the app can't be started, the environment is read-only, or there's no API surface in scope — **skip with a
one-line note** in the report. Do not block the review on it.

---

## Phase 3 — Compile findings

1. Collect every finding from all dispatched agents (+ live testing).
2. **De-duplicate** — the same issue raised by two agents becomes one finding noting both sources.
3. **Group by root cause** — cluster findings that share a fix (e.g. several "missing input validation", several "N+1").
4. **Sort groups** by highest severity (Critical first).

---

## Phase 4 — Review Triage gate

Reviewer output is **advisory input, never auto-applied**. Load `references/triage.md` and classify every group as
**Blocker / In-scope / Out-of-scope**, with the post-triage calibration check. Only Blockers and agreed In-scope
items proceed to fixing; everything else is documented with a one-line rationale.

---

## Phase 5 — Fix (advisory + user-gated)

Process triaged Blockers, highest severity first. **Do not silently apply or silently drop anything:**

- **Blocker** — agree the fix with the user, apply it as a focused change, then **re-dispatch only the affected
  reviewer** to confirm it's resolved. Re-run at most until resolved or the user accepts it as a known follow-up.
- **In-scope recommendation** — decide with the user: fix now or defer to a follow-up. Record the decision.
- **Out-of-scope** — leave documented in the report with the rationale; do not touch.

No autonomous fix loop, no scope creep — fix only what was found and agreed.

---

## Phase 6 — Final verification & report

1. Run the project's verification commands — its tests / lint / type-or-contract check / build. Capture the real
   output; never claim green without it. (Use `superpowers:verification-before-completion` if that plugin is installed.)
2. Write the report using `references/review-report-template.md` to `docs/reviews/YYYY-MM-DD-review.md` (append `-2`,
   `-3` for repeat runs the same day). `docs/reviews/` is a normal, committable location.
3. Present an inline summary: scope, which reviewers ran, post-triage counts (Critical / In-scope / Out-of-scope),
   what was fixed, what's deferred, and the final verification result.

**Stop there.** Do not push, do not open or update a PR/MR, do not move a Jira ticket — those are the user's calls.

---

## Anti-patterns

- **Don't dispatch all reviewers blindly** — pick by what changed (`references/dispatch-matrix.md`).
- **Don't auto-apply reviewer output** — everything goes through the Triage gate.
- **Don't fix autonomously or beyond scope** — fixes are agreed with the user, focused, re-validated.
- **Don't leave processes running** — always kill what Phase 2 started.
- **Don't claim PASS without evidence** — run the verification command and read its output first.
- **Don't push or open a PR/MR.**
