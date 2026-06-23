---
name: develop
description: |
  Orchestrator for the full development cycle. Validates the input source (a Jira ticket key, a Confluence URL/ID,
  a local design-doc path, or an inline description — at least one), dispatches the load by source type (Jira →
  /dev:analyze-jira-ticket for a code-aware context dump; Confluence → read-only fetch; local file → Read; inline →
  use the prompt), then — for Jira sources only — asks whether to formalize a written plan via /dev:plan or proceed
  with the context dump as-is. It delegates the doing phase (delivery model + git setup + TDD + review + verification)
  to /dev:implement-from-analysis, then branches on the returned delivery model: local-only stops gracefully; a single
  PR/MR is opened via /dev:open-pr; an umbrella multi-PR/MR runs a per-unit loop. Use before touching implementation
  code when starting any new development phase, plan, or feature cycle.

  English triggers: "develop", "dev cycle", "start dev cycle", "next plan", "implement next", "run the full
  development cycle", "take this from design to PR", "take this from design to MR", "/dev:develop"

  České spouštěče: "vývojový cyklus", "spusť vývojový cyklus", "další plán", "implementuj další", "rozjeď vývoj",
  "od návrhu k PR", "od návrhu k MR", "naimplementuj a otevři PR", "/dev:develop"

  Do NOT apply when: the user only wants to read a ticket (use /common:read-jira-ticket), only wants to analyse
  a ticket without driving the whole cycle (use /dev:analyze-jira-ticket), only wants to review existing changes
  (use /dev:code-review), or already has an approved plan and just wants to implement it (use
  /dev:implement-from-analysis).
user-invocable: true
argument-hint: '[source: jira-key | confluence-url | local-file-path | inline-description] [jira-key-or-jql]'
allowed-tools:
  Read, Write, Edit, Bash, Glob, Grep, Agent, Skill, AskUserQuestion
effort: xhigh
---

# Develop — Full Development Cycle (orchestrator)

Orchestrate the complete development cycle by **composing other skills**, keeping each stage a disciplined, reviewable
checkpoint rather than collapsing the whole workflow into one undifferentiated session.

Develop validates the input, dispatches the load by source type, asks the optional plan-formalization question (Jira
sources only), delegates the doing phase to `/dev:implement-from-analysis`, then branches on the delivery model that
skill returns — stopping for local-only, opening a single PR/MR via `/dev:open-pr`, or running a per-unit umbrella loop.

This skill is an **orchestrator**: each heavy stage is owned by a consolidated brick, and develop just sequences them
and keeps the source-dispatch + delivery-model branching. It does **not** re-describe a brick's internals — it names
the brick and the hand-off. The delegations:

- **Source load (Jira)** is owned by **`/dev:analyze-jira-ticket`** — it loads the ticket, scans the code, and returns
  a structured context dump. Develop does **not** restate that dump's format or re-run the code scan.
- **Optional plan formalization (Jira only)** is owned by **`/dev:plan`** (heavyweight, solution-doc-based), which in
  turn expects a **`/dev:solution-doc`** as input.
- **The doing phase** (delivery model + git setup + test-first build loop + review + verification) is owned by
  **`/dev:implement-from-analysis`** — it asks the user for one of the four delivery models and returns the chosen one.
- **The PR/MR open** (single PR/MR) is owned by **`/dev:open-pr`** — our merged skill that runs the pre-flight
  checklist (env-var propagation, version bump, changelog, `CLAUDE.md` review) **and** pushes + opens the PR/MR in one
  call. There is **no separate pr-prep step**.
- **Broader cross-system context** (Jira + Confluence together), when the single source isn't enough, is available via
  **`/common:context-pull`**. The primary load is the Step-1 source-dispatch — only reach for context-pull when you
  genuinely need the wider picture; don't duplicate what source-dispatch already covered.
- **Confluence publishing** (any durable doc develop writes back, e.g. a brainstorm or plan write-back) is routed
  through **`/common:confluence-update`**.
- **Local commits** go through **`/common:git-commit`**; **Jira transitions** through **`/common:jira-update`** — both
  user-gated.

> **Optional enhancement:** the finishing flow (Step 7) can lean on the `superpowers` plugin's
> `finishing-a-development-branch` skill if installed. It is an enhancement, not a requirement — this skill states the
> same discipline in its own words so it is self-contained without it.

**Announce at start:** state that you are starting the `/dev:develop` cycle.

## Skill chain (who does what)

| Phase                                       | Owner                                                        |
| ------------------------------------------- | ------------------------------------------------------------ |
| Validate input source                       | `/dev:develop` (Step 0)                                       |
| Load + code scan (Jira)                     | `/dev:analyze-jira-ticket` (load + scan + context dump)       |
| Load (Confluence / local / inline)          | inline in `/dev:develop` Step 1 (no code scan)               |
| Heavy plan creation (optional, Jira only)   | `/dev:plan` (← needs a `/dev:solution-doc` as input)         |
| Delivery model + git setup + build + review | `/dev:implement-from-analysis`                               |
| Open single PR/MR (Models A and B)          | `/dev:open-pr` (merged checklist + push + open)              |
| Open umbrella sub-PR/MR (Model C)           | inline in `/dev:develop` Step 6 (`references/multi-pr-template.md`) |
| Per-unit loop (Model C)                     | `/dev:develop` Step 6 (orchestration only)                   |
| Finishing                                   | `superpowers:finishing-a-development-branch` (if installed)  |

---

## Input

`$ARGUMENTS`

- **`$1` = primary source (REQUIRED — at least one signal)** — one of:
  - Jira key (`PROJ-123`)
  - Confluence URL/ID (a wiki page URL on your Confluence site, or a plain numeric page ID)
  - Local file path ending in `.md` / `.txt` (relative or absolute, e.g. `docs/handover.md`) that exists
  - Inline description (anything else — treat the user's prompt itself as the source)
- **`$2` = optional Jira scope** — issue key, epic key, project key, or a full JQL string for sibling/subtask context.
  Passed through downstream if relevant.

---

## Step 0 — Validate source

Look at `$1` and detect the source type:

| `$1` matches                                                     | Source type        |
| ---------------------------------------------------------------- | ------------------ |
| `[A-Z]+-\d+`                                                     | Jira ticket        |
| A Confluence wiki URL, or a numeric page ID                      | Confluence         |
| Path ending in `.md` / `.txt` (relative or absolute) that exists | Local file         |
| Anything else (free-form text)                                   | Inline description |

If **NONE** of these can be resolved (no `$1`, no obvious local file in the repo, no inline context):

- **Do not proceed.**
- Tell the user the command needs at least one source — a Jira key, a Confluence URL, a local file path (e.g. a design
  doc), or a description in chat — and ask them to retry with one of those.
- **Stop.**

---

## Step 1 — Dispatch + load by source type

Load the source content (or delegate the load) based on the type detected in Step 0.

### 1a — Jira ticket

Invoke **`/dev:analyze-jira-ticket`** with `$1` as its argument. That skill loads the ticket (via
`/common:read-jira-ticket`), detects the repo structure, scans the relevant packages, and produces a **structured
context dump**. It does **not** propose a plan, ask Q&A, or hand off — its output is the deliverable. Capture it.
Proceed to **Step 2**.

### 1b — Confluence URL

Fetch the page **read-only** via `confluence_get_page` (it returns the body
as Markdown; the Hub uses the active Atlassian site, so no `cloudId` is passed). Extract title + body. **No code scan.** Treat the
fetched content as the plan input. **Skip Step 2** — proceed to **Step 3**.

### 1c — Local file

Use **`Read`** to load the file (full file if small, otherwise targeted reads). Treat the content as the plan input.
**Skip Step 2** — proceed to **Step 3**.

### 1d — Inline description

Use the user's prompt itself as the plan input. **Skip Step 2** — proceed to **Step 3**.

> If a wider cross-system picture is needed (related Jira work + the relevant Confluence space) that the single source
> doesn't give, invoke **`/common:context-pull`** scoped by `$2` / the source's topic — but only when source-dispatch
> above isn't enough. Don't duplicate context the dispatch already loaded.

---

## Step 2 — [Jira sources only] Optional plan formalization

Runs **only when Step 1 took the Jira branch (1a)**. For Confluence / local / inline sources, develop already proceeded
to Step 3.

Show the user the structured context dump from `/dev:analyze-jira-ticket` and ask:

> "Analysis complete. The output above is a structured context dump (ticket content + related code + observations) —
> not yet a formal implementation plan. Two options:
>
> **(a) Formalize into a plan via `/dev:plan`** — heavyweight: edge-case discovery, effort estimates, parallel
> architectural review, plan written to Confluence on sign-off. Best for non-trivial work where the ROI of a formal
> plan is worth it.
>
> **(b) Proceed directly to implementation** — treat this context dump as the plan and pass it to
> `/dev:implement-from-analysis`. Best for thin tickets where the description + code observations are enough to start.
>
> Which?"

| User picks | What develop does                                                                                                                                                                                                                                                                                                            |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **(a)**    | Invoke **`/dev:plan`** and wait for it to complete. It expects a **`/dev:solution-doc`** Confluence page as input — if one isn't already linked from the ticket, tell the user: _"`/dev:plan` needs a solution-doc URL. Run `/dev:solution-doc` first, then re-invoke me with the resulting URL as `$1`."_ and stop. Otherwise capture the produced plan and use it as the plan input for Step 3. |
| **(b)**    | Use the context dump from Step 1a as the plan input for Step 3.                                                                                                                                                                                                                                                              |

---

## Step 3 — Delegate the build to `/dev:implement-from-analysis`

Invoke **`/dev:implement-from-analysis`** with the plan/context (from Step 1 or Step 2) + the ticket key (when `$1` was
Jira). That skill owns the whole doing phase — it asks the user for one of the four delivery models, does the matching
git setup, runs the test-first build loop with scope discipline, delegates the local review to `/dev:code-review`, runs
final verification, and returns a handoff that **includes the chosen delivery model**, the branch, the commit count,
and the findings summary. Its own SKILL.md documents those internals — don't restate them here.

**Wait for the handoff.** Read the returned delivery model and branch, then branch in Steps 4–7. Do **not** re-run
reviewers, re-implement, or re-do verification — `/dev:implement-from-analysis` already covered those gates.

The four delivery models (as defined and asked by `/dev:implement-from-analysis`):

- **A** — single PR/MR via git worktree
- **B** — single PR/MR on the current branch (no worktree)
- **C** — umbrella + stacked sub-branches (multi-PR/MR)
- **D** — local-only (no push, no PR/MR)

---

## Step 4 — Branch on the returned delivery model

| Returned model         | What develop does next                                                                                          |
| ---------------------- | --------------------------------------------------------------------------------------------------------------- |
| **D (local-only)**     | **Stop gracefully** — see Step 5.                                                                                |
| **A or B (single PR/MR)** | Open the single PR/MR via `/dev:open-pr` — see Step 6.                                                        |
| **C (umbrella/multi)** | Open each sub-PR/MR inline and run the per-unit loop — see Step 6.                                               |

---

## Step 5 — Model D: stop gracefully

Implementation is complete locally and Model D means no push and no PR/MR. Announce:

> "Implementation complete on `<branch>` with N local commits, M critical findings resolved. Model D (local-only)
> chosen — no PR/MR will be opened. Push when ready (`git push -u origin <branch>`), then open a PR/MR with
> `/dev:open-pr` if you decide to."

Do **not** continue. Push and PR/MR are user-led.

---

## Step 6 — Open the PR/MR (forks by delivery model)

### 6a — Models A and B: delegate to `/dev:open-pr`

For both Model A (worktree) and Model B (current branch), invoke **`/dev:open-pr`** in **one call** (add a `draft`
token for a draft, and a reviewer token if the user named one; otherwise it prompts). It is our **merged** skill: it
runs the pre-flight checklist (propagate new env vars, bump the version, append the changelog, review `CLAUDE.md`,
summarize the change) **and** then pushes + opens the PR/MR with the reviewer requested — the upstream's separate
pr-prep + open-pr steps collapse into this single call. If it can't resolve the Jira key from the branch / commits, it
asks the user. Its own SKILL.md documents the internals — don't restate or duplicate them. After it returns, go to
**Step 7**.

### 6b — Model C: open the umbrella sub-PR/MR here, then loop

The umbrella / stacked base refs don't fit `/dev:open-pr`'s single-base, single-ticket open, so develop opens each
sub-PR/MR inline. For the pre-flight checklist, run **`/dev:open-pr prep-only`** (Phase-1 checklist only — env-var
propagation, version bump, changelog, `CLAUDE.md` review — no push, no open), **commit** the files it changes on the
current sub-branch via `/common:git-commit`, then open the sub-PR/MR from **`references/multi-pr-template.md`** (read it
first). Pull `Version` / `Environment variables` / change summary from that `prep-only` run — don't recompute them.

`references/multi-pr-template.md` carries the full umbrella-open detail: base-ref selection (umbrella vs stacked on the
preceding sub-PR/MR head), the series-context section, the title format, previous-PR/MR discovery, and the
host-agnostic push + create. Reviewer request and the optional Jira review field are intentionally **out of scope** for
the umbrella path. See `dev/skills/implement-from-analysis/references/conventions.md` for the branch/base conventions.

After a sub-PR/MR opens, report its URL, base / head branches, commit count, and any follow-up (e.g. "after the
preceding sub-PR/MR merges, retarget this one's base at the umbrella").

**Per-unit loop.** After the current sub-PR/MR is merged into the umbrella (`feature/<TICKET>`):

1. Update the plan tracking doc (if the project keeps one) to mark the current sub-unit Done.
2. Ask the user: sub-PR/MR `<N>` is merged into the umbrella; continue with sub-PR/MR `<N+1>`?
3. If yes, source the next sub-unit's plan from the next section of the plan document if the plan is a doc; if the work
   was decomposed inline, summarize the next sub-unit from the session context and confirm it with the user before
   re-delegating. Then **return to Step 3** (re-delegate to `/dev:implement-from-analysis` with that next sub-unit's
   plan), then Steps 4–6 again.
4. If no (the user wants a pause / different work), exit cleanly and document where you left off.

**Final umbrella merge.** After **all** sub-PR/MRs are merged into the umbrella, propose:

> "All sub-PR/MRs are merged. Continue with the final umbrella merge `feature/<TICKET>` → `<default-branch>`?"

This final merge typically goes through code review **again** (especially if the umbrella accumulated many sub-PR/MRs):
re-invoke **`/dev:implement-from-analysis`** with the umbrella as the working branch so its review pass runs against the
`<default-branch>...feature/<TICKET>` diff. Then go to **Step 7**.

---

## Step 7 — Finish

Wrap up (after the single PR/MR for A/B, or after the final umbrella merge for C):

- Run the development-branch finish flow — confirm everything is merged and decide how to integrate and clean up (e.g.
  via the `superpowers` plugin's `finishing-a-development-branch` skill, if installed). The discipline in our own
  words: confirm the work is merged, transition the Jira issue(s), and clean up the branch/worktree.
- Update the plan tracking doc (if any) — mark the whole feature/ticket Done.
- Transition the Jira issue(s) via **`/common:jira-update`** — **only with explicit user confirmation**; let the user
  click through the actual transition if they prefer.
- Clean up local branches (`git branch -d`) — only with user confirmation. Worktree cleanup (Model A only) via the same
  worktree flow `/dev:implement-from-analysis` used in setup.

---

## Important Reminders

- **Develop is an orchestrator.** It validates the source, dispatches the load, asks the optional plan question (Jira
  only), delegates the doing phase, and branches on the returned delivery model. It does **not** write plans, run code
  scans (that's `/dev:analyze-jira-ticket`), implement code, dispatch reviewers, or restate any brick's internals — it
  names the brick and hands off.
- **Source dispatch** — Jira → `/dev:analyze-jira-ticket`; Confluence → `confluence_get_page` (read-only); local file →
  `Read`; inline → use the prompt as-is. The primary load is the source-dispatch; reach for `/common:context-pull` only
  for a wider cross-system picture the single source doesn't give — don't duplicate.
- **The plan question runs ONLY for Jira sources.** For Confluence / local / inline, the content is expected to be a
  plan (or a detailed spec) and goes straight to implement. `/dev:plan` is heavyweight and needs a `/dev:solution-doc`
  as input — redirect there if the user chooses (a) without one.
- **Delivery model is asked by `/dev:implement-from-analysis`, not here.** Don't pre-empt the question; branch on the
  model it returns.
- **Model D terminates the cycle** at Step 5 — stop gracefully; push + PR/MR are user-led.
- **No separate pr-prep step.** `/dev:open-pr` is our **merged** prep+open skill — Models A and B call it **once**
  (checklist + push + open). Model C runs `/dev:open-pr prep-only` for just the checklist, commits it, then opens the
  sub-PR/MR here from `references/multi-pr-template.md`. Default language English; ask only on a concrete signal.
- **Code review BEFORE push** is owned by `/dev:implement-from-analysis` (it delegates to `/dev:code-review`) — don't
  re-dispatch reviewers from develop.
- **Implementation discipline** (TDD, scope discipline, no new TODO/FIXME, don't break interfaces, full suite after
  each task) is owned by `/dev:implement-from-analysis` — don't restate it here.
- **Publishing** any durable doc develop writes goes through `/common:confluence-update`; **local commits** via
  `/common:git-commit`; **Jira transitions** via `/common:jira-update`.
- **Never modify Jira/Confluence without explicit user confirmation** — reading is fine; transitions, comments, and
  page updates require an explicit "yes" in chat.
- **Auto-mode aware:** in auto mode, don't stop for low-risk routine decisions. But destructive / shared-system actions
  (`git push`, opening a PR/MR, Jira writes, DB writes) ALWAYS need explicit user confirmation regardless of mode.

---

## Decision Tree (quick reference)

See `references/decision-tree.md` for the full ASCII map of all steps and branches, plus the phase-ownership table.
