---
name: develop
description: |
  Orchestrates a complete development cycle from a source-of-truth to an opened PR/MR. Loads the
  source (a Confluence page, a local design doc, a Jira ticket, or a free-form prompt — at least one),
  reconciles it with the code, optionally brainstorms the gaps, writes a plan, chooses a delivery model
  (single PR/MR via worktree vs a multi-PR/MR split), implements task-by-task, runs an independent local
  code review BEFORE push, then pushes and opens a PR/MR with a thorough description. Use when starting any
  new development phase, plan, or feature cycle — invoke it before touching implementation code. The source
  is flexible: at least one of a Confluence URL/ID, a local file path, a Jira key, or an inline description
  must be provided.

  English triggers: "develop", "dev cycle", "start dev cycle", "next plan", "implement next", "run the full
  development cycle", "take this from design to PR", "/dev:develop"

  České spouštěče: "vývojový cyklus", "spusť vývojový cyklus", "další plán", "implementuj další", "rozjeď vývoj",
  "od návrhu k PR", "naimplementuj a otevři PR", "/dev:develop"

  Do NOT apply when: the user only wants to read a ticket (use /common:read-jira-ticket), only wants to analyse
  a ticket without driving the whole cycle (use /dev:analyze-jira-ticket), only wants to review existing changes
  (use /dev:code-review), or already has an approved plan and just wants to implement it (use
  /dev:implement-from-analysis).
user-invocable: true
argument-hint: '[source: confluence-url | local-file-path | jira-key | inline-description] [jira-key-or-jql]'
allowed-tools:
  Read, Write, Edit, Bash, Glob, Grep, Agent, AskUserQuestion, mcp__atlassian__*
effort: xhigh
---

# Develop — Full Development Cycle (source-flexible)

Orchestrate a complete development cycle, keeping each stage a disciplined, reviewable checkpoint rather than
collapsing the whole workflow into one undifferentiated session.

The **source of truth for scope** can be one of several things — pick the richest one available:

1. **Confluence page** — a fully-fledged design with decisions, scope, and acceptance criteria
2. **Local design doc** — a markdown file in the repo (e.g. a meeting transcript, a hand-written spec, handover notes)
3. **Jira ticket** — issue description + comments + linked subtasks
4. **Inline description** — the user types the requirements directly in chat

Jira issues separately show **how the design has already been broken down into concrete tasks** (subtasks, related
work, status). The local codebase shows **what has already been built**. The cycle reconciles all available signals
before touching new code.

**Announce at start:** state that you are starting the `/dev:develop` cycle.

> **Optional enhancement:** several stages below describe a discipline (brainstorming, plan-writing, isolated
> worktrees, task-by-task execution, verification-before-completion). If the `superpowers` plugin is installed you can
> lean on its skills (`brainstorming`, `writing-plans`, `using-git-worktrees`, `subagent-driven-development`,
> `verification-before-completion`, `finishing-a-development-branch`) to drive each one. They are an enhancement, not a
> requirement — this skill spells out the same discipline in its own words so it is fully self-contained without them.

The independent pre-push review in Step 7 is delegated to **`/dev:code-review`**, which owns the parallel reviewer-agent
dispatch and triage. The pre-PR/MR housekeeping in Step 7.5 is delegated to **`/dev:pr-prep`**, and the single-PR/MR
open in Step 8a is delegated to **`/dev:open-pr`**.

---

## Input

`$ARGUMENTS`

- **`$1` = primary source (REQUIRED — at least one signal)** — can be:
  - Confluence URL/ID (a wiki page URL on your Confluence site, or a plain numeric page ID)
  - Local file path (relative or absolute, e.g. `docs/handover.md`)
  - Jira key (`PROJ-123`)
  - Inline description (anything else — treat the user's prompt itself as the source)
- **`$2` = Jira scope (optional)** — issue key, epic key, project key, or a full JQL string for subtask discovery.

### Step 0: Input validation (mandatory)

Look at `$1` and detect the source type:

| `$1` matches                                                     | Source type        | Loader                                       |
| ---------------------------------------------------------------- | ------------------ | -------------------------------------------- |
| A Confluence wiki URL, or a numeric page ID                      | Confluence         | `mcp__atlassian__getConfluencePage`          |
| Path ending in `.md` / `.txt` (relative or absolute) that exists | Local file         | `Read`                                       |
| `[A-Z]+-\d+`                                                     | Jira ticket        | `/common:read-jira-ticket`                   |
| Anything else                                                    | Inline description | Use the user's prompt directly               |

If **NONE** of these can be resolved (no `$1`, no obvious local file in the repo, no inline context):

- **Do not proceed.**
- Tell the user the command needs at least one source — a Confluence URL, a local file (e.g. a design doc), a Jira key,
  or a description in chat — and ask them to retry with one of those.
- Stop.

If multiple signals are available (e.g. a Confluence URL + a Jira key + local notes), use them all — Confluence is
primary scope, Jira shows the breakdown, the local file may carry additional context.

If `$2` is missing, continue without separate Jira scope. Jira context is optional. If `$1` is itself a Jira ticket,
also fetch its parent / sibling subtasks (rich Jira context comes from `$1` alone).

---

## Step 1: Load Context

Load all available signals based on what's provided.

1. **Primary source:**
   - Confluence: extract the title, project goal, scope, key decisions, open questions, and acceptance criteria.
   - Local file: read it whole (or with offsets if huge), summarize the same fields.
   - Jira ticket: load via `/common:read-jira-ticket` for the description + comments. If it's a subtask, also fetch its
     parent + siblings.
   - Inline description: parse the user's prompt for goal, constraints, and success criteria.

2. **Jira tasks (`$2` if provided, OR siblings of `$1` if `$1` is itself a Jira key):**
   - If `$2` looks like an issue/epic key (`[A-Z]+-\d+`): load it, then `searchJiraIssuesUsingJql` with
     `parent = $2 OR "Epic Link" = $2` to see its children.
   - If `$2` looks like a project key: `searchJiraIssuesUsingJql` with `project = $2 ORDER BY created DESC`.
   - If `$2` contains spaces or `=`: use it as JQL directly.
   - Extract per issue: key, summary, status, parent/epic, assignee.

3. **Local repo state:**
   - Read the project `CLAUDE.md` (and any shared rule files it references) for project-specific conventions and
     data-safety rules.
   - Check for any existing spec / plan documents that might be relevant to the source (e.g. under a `docs/plans/` or
     `docs/specs/` directory if the project keeps them).
   - `git status`, `git branch --show-current`, `git log --oneline -10` to understand the current branch state and
     recent work.

4. **Summary before continuing:**
   - State the source (type + identifier), the Jira issues found (count + statuses, if any), the current branch, and a
     short scope summary.
   - **Don't ask about open questions yet** — go to Step 2 (code reconciliation) first; many "open questions" are
     answered by reading the code.

---

## Step 2: Code-vs-Source Reconciliation

**Goal:** figure out what from the source already exists in the code, what's missing, and where code and source
diverge. Do this **before asking the user anything** — most "open questions" are answerable from the code.

1. **Identify the key concepts from the source:**
   - List concrete entities, modules, interfaces, endpoints, schemas, configs, events — anything with a named code
     equivalent.
   - Examples: type/class names, function names, package/module names, env vars, DB tables, API routes, event names.

2. **Find them in the code:**
   - **Prefer symbol-level lookups** when a language server / code-intelligence tool is available — they are more
     precise than text search (find references, read a definition, hover, diagnostics).
   - **Fall back to `Glob` + `Grep`** for non-symbol identifiers — config keys, env vars, DB columns, API route
     strings, content in markdown / schema / config files.
   - Use `Glob` to narrow scope first.
   - Read files via `Read` — full file if it's small, otherwise targeted reads.
   - If Jira tasks are `Done` or `In Progress`, check git history (`git log --oneline -- <path>`,
     `git log --all --grep="<JIRA-KEY>"`) — work may already be on a branch.

3. **Build a reconciliation table** and show it to the user:

   | Concept from source       | State in code                                  | Note                            |
   | ------------------------- | ---------------------------------------------- | ------------------------------- |
   | `Client.start(ctx)`       | Exists in the jobs module                      | OK, missing cleanup at shutdown |
   | `IndexingPipeline`        | Doesn't exist                                  | Needs to be created             |
   | `CrawlerConfig.maxDepth`  | Exists, typed as a signed int; source says uint | **Mismatch — needs decision**  |
   | Event `crawl.completed`   | Doesn't exist                                  | Needs to be created             |

4. **Classify the findings:**
   - **Done / partially done** — already exists, matches the source. Note in the plan that we'll build on it.
   - **Missing but obvious** — the source + existing code give a clear direction. Goes straight into the plan.
   - **Real mismatches / unknowns** — code and source contradict, or the source leaves something open while the code
     already assumes something. **Only this bucket needs Step 3 brainstorming.**

5. **Sanity-check Jira vs code (when Jira context exists):**
   - A Jira issue is `Done` but the corresponding code isn't there → flag it; it might be reverted or on another branch.
   - A Jira issue is `In Progress` and a branch/worktree exists → mention it; it might not need to start from scratch.

---

## Step 3: Brainstorming — default ON, skip only for small + clean changes

**Brainstorming is the default.** It costs little and consistently catches scope and design gaps the source did not
spell out. **Run it unless ALL of the following are true:**

- The change is small and isolated (1–2 files, single logical concern, no architectural impact)
- The source is rich (a Confluence page with decisions and acceptance criteria, OR a thoroughly-written design doc, OR
  a detailed Jira ticket)
- Step 2 produced no items in "Real mismatches / unknowns"
- The open questions in the source are all answered by the code
- The user has not asked for brainstorming explicitly

If all five are true → go straight to Step 4 (write the plan). Tell the user: the change is small, the source is well
thought-out, and code reconciliation is clean — skipping brainstorming.

**In every other case, brainstorm.** Especially when:

- The source is raw (a meeting transcript without explicit decisions, hand-written notes, an inline description)
- Step 2 produced "Real mismatches" or "unknowns"
- The source has explicit open questions
- The change touches multiple modules / has architectural impact
- The user asked for it

Drive a structured, one-question-at-a-time exploration of intent, requirements, and design before any implementation
(e.g. via the `superpowers` plugin's `brainstorming` skill, if installed). Pass it the reconciliation table, the list
of unresolved items, and the source summary.

- Ask **one question at a time**.
- **Every question must reference a concrete finding** — not a hypothetical. Format: _"Source says X, but
  `<path/to/file>:42` does Y. Which is correct?"_
- Output: a refined scope for the plan + a list of decisions that should be reflected back into the source (tell the
  user to update the Confluence page / commit the updated design doc / add a Jira comment).

---

## Step 4: Write the Plan + Choose Delivery Strategy

**Two sub-steps.**

### 4a: Ask the user how to deliver

This is the **most important fork in the workflow**. Different shapes of work demand different delivery models. Ask the
user:

> "Before we write the plan — how do you want to deliver this work?
>
> **A) Single PR/MR via git worktree** _(recommended for cohesive features, one logical chunk)_
>
> - I create an isolated worktree, implement the entire plan, and open one PR/MR at the end.
> - The reviewer gets the whole solution at once and sees a coherent picture.
> - If something needs to be reverted, it's atomic.
>
> **B) Multi-PR/MR split** _(recommended for larger work, several logical steps, or when the reviewer can't comfortably
> review a large diff)_
>
> - I create an umbrella branch `feature/<TICKET>` directly (no worktree), and from it sub-branches
>   `feature/<TICKET>-<step1>`, `-<step2>`, etc.
> - Each sub-branch gets its own PR/MR against the umbrella branch.
> - After all sub-PRs/MRs are merged, a final umbrella merge goes to the default branch.
> - The reviewer gets smaller, focused diffs, and reviews can run in parallel.
>
> Which model?"

Wait for an explicit answer (A or B). The choice determines the rest of the workflow.

### 4b: Write the plan

Write a clear, step-by-step implementation plan the user can review (e.g. via the `superpowers` plugin's
`writing-plans` skill, if installed). Save it under the project's plan directory if it keeps one (e.g.
`docs/plans/YYYY-MM-DD-<short-name>.md`, or `YYYY-MM-DD-<TICKET>-pr-<N>-<short-name>.md` for the multi-PR/MR model — one
plan per PR/MR).

In the plan:

- Explicitly link the source (Confluence URL, local file path, Jira key) and any related Jira tickets.
- Include a short "Existing state" section summarizing the reconciliation table.
- For **model A (single PR/MR)**: one plan covering all tasks.
- For **model B (multi-PR/MR)**: write the plan for **the next PR/MR only**. Include a short "Series context" section
  listing what comes before/after (which PRs/MRs are done / current / pending). Subsequent PR/MR plans are written when
  you reach them — don't pre-write them all at once; scope evolves.

**Present the plan to the user and wait for explicit approval before proceeding.**

---

## Step 5: Git Setup (depends on the delivery model)

See `references/conventions.md` for the full table of branch naming, worktree paths, PR/MR base refs, and merge
direction by model — including the first-time umbrella setup commands and the stacked-PR/MR retargeting flow.

- **Model A (single PR/MR):** create an isolated worktree (a git worktree, or the `superpowers` plugin's
  `using-git-worktrees` skill if installed).
- **Model B (multi-PR/MR split):** no worktree; create the umbrella branch on the remote once, then a sub-branch per
  PR/MR.

After branch setup, run the test suite (or `build` + `lint` if there's no test runner) to confirm a clean baseline.

---

## Step 6: Implementation

Execute the plan task by task, applying disciplined test-first development (e.g. via the `superpowers` plugin's
`subagent-driven-development` and `test-driven-development` skills, if installed; otherwise sequence the tasks
yourself).

Constraints to carry into every task:

- **TDD when a test runner exists**: write a failing test, implement until it passes, commit. Never write the
  implementation before a test exists.
- **If the project has no test runner, don't invent one** just for this task — adding a new test framework is its own
  decision, not a side effect of one feature. Default behaviour: _describe the expected behavior → implement → manually
  verify → commit_. Verification must be explicit: run the concrete command, check the output, do a visual check. The
  project `CLAUDE.md` may make this explicit ("do not invent one"); even without that rule, treat it as the default.
- **No new TODO/FIXME in the code this task adds or changes.** Existing TODO/FIXME in touched files are out of scope —
  leave them alone. If something is deferred for the current task, add a task to the plan file instead of a comment in
  the code.
- **Don't break existing interfaces** without a documented reason.
- **Run the full test suite (or `build` + `lint` if no tests) after each task** before starting the next.
- Make local commits via `/common:git-commit` (conventional commits, imperative mood, explain *why* not *what*).
- If a task corresponds to an existing Jira issue, you may transition its status — but **only with explicit user
  confirmation in chat** (e.g. via `/common:jira-update` or `mcp__atlassian__transitionJiraIssue`).

For **model B (multi-PR/MR)**: implementation is per current PR/MR only. Do not batch all PRs/MRs into one
implementation block — finish the current PR/MR's work, push and merge it, then come back to write & implement the next
one's plan.

---

## Step 7: Pre-Push Code Review (BEFORE push, BEFORE PR/MR creation)

**This step happens BEFORE any `git push` and BEFORE opening a PR/MR.** Goal: catch issues locally with independent
reviewers, so the colleagues' PR/MR review is faster and finds fewer real issues. The PR/MR description (Step 8) will
reference the local review summary.

**Critical**: run this for **EVERY** push that opens or updates a PR/MR. In model B, this means before each sub-PR/MR
push. In model A, this means before the final push.

Delegate the review to **`/dev:code-review`** — it owns the reviewer selection (its `references/dispatch-matrix.md`),
dispatches the relevant `dev:` reviewer agents **in parallel**, triages what they find, and drives user-gated fixes.
This is the same machinery `/dev:implement-from-analysis` uses, so the `/dev` chain stays consistent. Do **not**
hand-roll a separate review here.

- **Scope to pass it**: the exact diff range for the current push — `git diff <base-ref>...HEAD`
  (Model A: base = default branch; Model B: base = umbrella, or the preceding PR/MR head if stacked). You can also pass
  the plan file path and the source (Confluence URL / local doc path / Jira key + summary) as context.
- The reviewer agents run outside the main context and read their own rules — `/dev:code-review` handles that handoff;
  you don't pre-load rules for them here.

**Action on findings** (`/dev:code-review` triages and drives these; this is the contract `develop` enforces):

| Finding                                          | Action                                                                                                     |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| **Critical Issue** (any reviewer)                | **Must fix before push.** Fix as an additional commit on the current branch.                               |
| **Contract gap** between layers (e.g. UI↔API)    | Treat as Critical — **must fix before push** (or document an explicit follow-up agreed with the user).     |
| **Recommendation** (any reviewer)                | Decide **with the user**: fix now, or defer to a follow-up ticket. Do not silently drop or silently apply. |
| **Client Gaps / Open Questions** (business-case) | **Surface to the user, do not invent answers.** Report at the end of the consolidation.                    |

For each Critical, agree the fix with the user, apply it, then **re-review only the affected area** for a second pass to
confirm the fix is correct. Don't re-run reviewers whose area didn't change.

**Before proceeding to Step 8**, present a consolidated review summary to the user, including:

- The per-reviewer verdict (Approved / Approved with fixes / Needs rework) and which agents ran.
- The list of Critical Issues + contract gaps fixed (with commit hashes).
- The Recommendations and the user's decision on each (fixed now / deferred to which ticket).
- The Client Gaps / Open Questions raised by the business-case evaluator (informational — for the user to resolve).

---

## Step 7.5: Pre-PR/MR housekeeping (`/dev:pr-prep`)

After Step 7's review fixes are committed, before push. `/dev:open-pr` is read-only with respect to the worktree — it
never propagates env vars or bumps the version, it only reads them. Those mutations are `/dev:pr-prep`'s job, so run it
here.

Invoke **`/dev:pr-prep`** — **with no argument** (no "create PR/MR" token; PR/MR creation stays in Step 8). It
propagates new env vars, bumps the version, appends the changelog, and reviews `CLAUDE.md` — its own SKILL.md documents
the steps, don't restate them here. **Commit the files it changes** (env files, the version/manifest file, the
changelog, `CLAUDE.md`) on the current branch before Step 8.

Its version / env / summary then feed Step 8: **Model A** — `/dev:open-pr` reads them off the branch diff via its own
handoff contract (nothing to forward by hand); **Model B** — drop them into the `references/multi-pr-template.md` body.
Either way, don't regenerate them.

---

## Step 8: Open the PR/MR (the mechanism forks by delivery model)

After Step 7 review fixes and Step 7.5 housekeeping commits are on the branch, open the PR/MR. **How** depends on the
delivery model chosen in Step 4a:

- **Model A (single PR/MR)** → delegate the whole open entirely to the **`/dev:open-pr`** skill. Its PR/MR body is the
  team-agreed standard, and it also requests the configured reviewer. Don't hand-roll a body.
- **Model B (umbrella / multi-PR/MR)** → **do not use `/dev:open-pr`** — its single-base, single-ticket assumptions
  don't fit umbrella / stacked branches. Open the sub-PR/MR here, composing the body from
  `references/multi-pr-template.md`, which is a copy of the open-pr body format adapted for a PR/MR series so umbrella
  sub-PRs/MRs still look like the team standard.

### 8a — Model A: delegate to `/dev:open-pr`

Just invoke it — **`/dev:open-pr`** (add a `draft` token if it should be a draft, and a reviewer token if the user
named one; otherwise it prompts for the reviewer). It owns the whole open: push, the existing-PR/MR check, the
team-agreed body, the push + PR/MR creation on your git host, the reviewer request, and (if the project wires it) the
Jira review field. If it can't resolve the Jira key from the branch / commits, it asks the user for it.

`/dev:open-pr` already documents how it consumes `/dev:pr-prep` output — don't restate it here. The Step 7.5
housekeeping is already committed on the branch, so it derives `Version` / `Environment variables` read-only from the
diff. Don't re-implement or duplicate any of that.

### 8b — Model B: open the umbrella sub-PR/MR here

1. **Language** — default to English for the body + title; ask only on a concrete signal otherwise (the user said so,
   the source is in another language, or a prior PR/MR in the series used one).
2. **Base ref:**
   - the preceding PR/MR merged → base = `feature/<TICKET>` (umbrella)
   - the preceding PR/MR still open (stacked) → base = `feature/<TICKET>-<prev-step>` (the head branch of the preceding
     open PR/MR). Note it in the body (the series-context section). After it merges, retarget the base at the umbrella
     (see `references/conventions.md` and `references/multi-pr-template.md`).
3. **Compose the body** from `references/multi-pr-template.md` — read it first. It mirrors the open-pr section order and
   adds the series-context section, previous-PR/MR discovery, and the stacked-base note. Pull `Version` /
   `Environment variables` from Step 7.5 — don't recompute them.
4. **Title:** `<TICKET> PR/MR <N>: <short summary>` (under ~80 chars).
5. **Push + create** the PR/MR on your git host:
   - Push the sub-branch: `git push -u origin <branch-name>`.
   - Open the PR/MR with the chosen base, head, title, and the composed body. Use whatever your git host exposes — its
     CLI or its web UI (the client wires their host's CLI/MCP here). When the host's CLI accepts a body on the command
     line, pass it via a quoted heredoc so tables / code fences / diagrams survive intact (see
     `references/multi-pr-template.md`).
6. **Reviewer / Jira review field:** not handled via `/dev:open-pr` for Model B. Don't request a reviewer by default; if
   the team wants the Jira review field set on sub-PRs/MRs too, do it manually — the umbrella path intentionally does
   not replicate open-pr's reviewer machinery.

After the PR/MR opens, report: the PR/MR URL, the base / head branches, the commit count, and any follow-up (e.g.
"after PR/MR II merges, retarget this one's base at `feature/<TICKET>`").

---

## Step 9: Per-PR/MR loop (Model B only)

After the current sub-PR/MR is merged into the umbrella (`feature/<TICKET>`):

1. Update the plan tracking doc (if the project keeps one) to mark the current PR/MR as Done.
2. Ask the user: PR/MR `<N>` is merged into the umbrella; continue with PR/MR `<N+1>`? (You'll write the next plan based
   on the post-`<N>` state.)
3. If yes, return to Step 4b (write the next PR/MR's plan), then Steps 5–8.
4. If no (the user wants a pause / different work), exit cleanly and document where you left off.

After **all sub-PRs/MRs are merged into the umbrella**, propose the final umbrella merge:

> "All sub-PRs/MRs are merged. Continue with the final umbrella merge `feature/<TICKET>` → `<default-branch>`?"

This final merge typically goes through code review **again** (especially if the umbrella accumulated many sub-PRs/MRs)
— repeat Step 7 with `<default-branch>...feature/<TICKET>` as the diff range.

---

## Step 10: Finish (after the final merge)

Wrap up:

- Run the development-branch finish flow — confirm everything is merged and decide how to integrate and clean up (e.g.
  via the `superpowers` plugin's `finishing-a-development-branch` skill, if installed).
- Update the plan tracking doc (if any) — mark the whole feature/ticket as Done.
- Optionally suggest the user transition Jira issues to Done — **only with explicit confirmation**, and let the user
  click through the actual transition if they prefer.
- Clean up local branches (`git branch -d`) — only with user confirmation.
- Worktree cleanup (model A only) via the same worktree flow used in Step 5.

---

## Important Reminders

- **Source flexibility:** any of Confluence / local file / Jira / inline description is valid. If multiple are
  provided, use them all; the richest one is primary scope.
- **Brainstorming is the default.** Skip only when the change is small + isolated AND the source is rich AND
  reconciliation is clean AND the user did not ask for it.
- **Delivery model is a user choice.** Always ask in Step 4a; don't assume a default.
- **Code review BEFORE push, every push.** Delegate to `/dev:code-review` (it selects and dispatches the `dev:`
  reviewer agents in parallel and triages). Fix Critical Issues + contract gaps before push; decide Recommendations
  with the user; surface business-case Client Gaps / Open Questions only.
- **Run `/dev:pr-prep` before push (Step 7.5)** — without a create-PR/MR token. It propagates new env vars, bumps the
  version, appends the changelog, reviews `CLAUDE.md`, and emits the change summary. Its artifacts feed Step 8's PR/MR
  body — do not regenerate them.
- **PR/MR opening forks by delivery model.** Model A → delegate to `/dev:open-pr` (team-agreed body + reviewer). Model B
  → open here with `references/multi-pr-template.md` (the open-pr body format + a series-context section). Default
  language English; ask only on a concrete signal otherwise.
- **TDD when possible**, structured manual verification when there's no test runner — and don't invent a test runner
  just for one task.
- **No new TODO/FIXME in code this task adds or changes.** Existing TODO/FIXME in touched files are out of scope. Add a
  task to the plan for deferred work instead.
- **Extensibility:** don't change existing interfaces without reason.
- **Never modify Jira/Confluence without explicit user confirmation** — reading is fine; transitions, comments, and
  page updates require an explicit "yes" in chat.
- **Auto-mode aware:** if the user is in auto mode, don't stop for low-risk routine decisions. But destructive /
  shared-system actions (`git push`, opening a PR/MR, Jira writes, DB writes) ALWAYS need explicit user confirmation
  regardless of mode.

---

## Decision Tree (quick reference)

See `references/decision-tree.md` for the full ASCII map of all steps and branches.
