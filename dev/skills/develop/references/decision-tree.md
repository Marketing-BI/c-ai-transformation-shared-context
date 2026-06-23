# Decision Tree — develop quick reference

Visual map of the orchestrator. Develop: **validate source → dispatch + load** (Jira uses `/dev:analyze-jira-ticket`,
others load inline) → **optional plan formalization** (Jira only) → **delegate the doing phase** to
`/dev:implement-from-analysis` → **branch on the returned delivery model** (D stops · A/B open one PR/MR via
`/dev:open-pr` · C runs the umbrella loop) → finish.

Develop does **not** write plans itself, run code scans (that's `/dev:analyze-jira-ticket`), implement code, dispatch
reviewers, or restate a brick's internals (those live in `/dev:implement-from-analysis`). Host-agnostic throughout:
"PR/MR" is the generic pull/merge request, every git-host step is "your git host's CLI or web UI".

```
develop invoked
    │
    ▼
Step 0: Validate source ($1)
    ├─ Jira key?        → OK
    ├─ Confluence URL?  → OK
    ├─ Local .md/.txt?  → OK
    ├─ Inline desc?     → OK
    └─ None?            → STOP, ask user for any source
    │
    ▼
Step 1: Dispatch + load by source type
    ├─ Jira       → invoke /dev:analyze-jira-ticket
    │                 (load via /common:read-jira-ticket + repo detect + code scan +
    │                  structured context dump — no Q&A, no plan)
    │                 → continue to Step 2
    │
    ├─ Confluence → mcp__claude_ai_Connectivity_Hub__atlassian__confluence_get_page (read-only; no code scan)
    │                 → SKIP Step 2 → Step 3
    │
    ├─ Local file → Read
    │                 → SKIP Step 2 → Step 3
    │
    └─ Inline     → use prompt as-is
                      → SKIP Step 2 → Step 3
    (wider cross-system context, only if the single source isn't enough:
     /common:context-pull scoped by $2 / source topic — don't duplicate)
    │
    ▼
Step 2: [Jira only] Optional plan formalization
    │   Show context dump; ask user: "Formalize via /dev:plan, or proceed directly?"
    │
    ├─ (a) Formalize → invoke /dev:plan (needs a /dev:solution-doc as input;
    │                  if missing, redirect user to /dev:solution-doc first)
    │                  → capture produced plan → continue
    │
    └─ (b) Proceed   → use context dump from Step 1a as the plan input
    │
    ▼
Step 3: DELEGATE the doing phase to /dev:implement-from-analysis
    │   pass: plan/context + ticket key (if Jira)
    │
    │   implement-from-analysis runs internally:
    │     1. confirm preconditions
    │     2. ASK delivery model:
    │          A - single PR/MR via worktree
    │          B - single PR/MR on current branch (no worktree)
    │          C - umbrella + stacked sub-branches (multi-PR/MR)
    │          D - local-only (no push, no PR/MR)
    │     3. git setup per model
    │     4. implement task-by-task (test-first + scope discipline)
    │     5. delegate review to /dev:code-review (reviewer dispatch + triage + fixes)
    │     6. final verification
    │     7. handoff: chosen model + branch + commit count + findings summary
    │
    ▼
Step 4: Branch on the returned delivery model
    ├─ D (local-only)          → Step 5: STOP gracefully
    ├─ A / B (single PR/MR)     → Step 6a
    └─ C (umbrella/multi)       → Step 6b
    │
    ├──────────────────────────────────────────────────────────────┐
    ▼                                                                ▼
Step 5: Model D — stop gracefully                          Step 6: Open the PR/MR
    announce local commits ready;                              │
    push + PR/MR are user-led                                  │
                                                               ▼
                              ┌────────────────────────────────┴───────────────────────────┐
                              ▼                                                              ▼
                  Step 6a: Models A & B                                    Step 6b: Model C (umbrella)
                  → invoke /dev:open-pr ONCE                               → /dev:open-pr prep-only (checklist only)
                    (our MERGED prep+open skill:                            → commit its changes (/common:git-commit)
                     checklist + push + open in one;                       → open sub-PR/MR HERE from
                     NO separate pr-prep step)                               references/multi-pr-template.md
                    → it requests the reviewer,                             (base = umbrella, OR stacked on the
                      asks for the Jira key if needed                        preceding sub-PR/MR head if still open;
                  → Step 7                                                   series-context + heredoc body;
                                                                            no reviewer / Jira field here)
                                                                          → per-unit loop: back to Step 3 for the
                                                                            next sub-unit; when all merged, final
                                                                            umbrella merge → re-invoke
                                                                            /dev:implement-from-analysis for the
                                                                            full-diff review pass
                                                                          → Step 7
    │
    ▼
Step 7: Finish — superpowers:finishing-a-development-branch (if installed);
    Jira transitions via /common:jira-update (user-gated); branch/worktree cleanup
```

## Phase ownership table

| Phase                                       | Owner                                                        |
| ------------------------------------------- | ------------------------------------------------------------ |
| Validate input source                       | `/dev:develop` (Step 0)                                       |
| Load + code scan (Jira)                     | `/dev:analyze-jira-ticket` (load + scan + context dump)       |
| Load only (Confluence)                      | `mcp__claude_ai_Connectivity_Hub__atlassian__confluence_get_page` (inline in develop 1b)   |
| Load only (local file)                      | `Read` (inline in develop 1c)                                |
| Load only (inline)                          | none — use prompt as-is (develop 1d)                         |
| Wider cross-system context (optional)       | `/common:context-pull` (only when source-dispatch isn't enough) |
| Plan formalization (optional, Jira only)    | `/dev:plan` — heavyweight                                     |
| Solution doc (prerequisite for `/dev:plan`) | `/dev:solution-doc` — user-invoked separately                |
| Delivery model + git setup + build + review | `/dev:implement-from-analysis` (asks the model, returns it)  |
| Scope discipline + TDD + local commits      | inside `/dev:implement-from-analysis`                        |
| Local code review (pre-push)                | `/dev:code-review` (dispatched by `/dev:implement-from-analysis`) |
| Branch/base conventions (4 models)          | `/dev:implement-from-analysis` → `references/conventions.md` |
| Open single PR/MR (Models A and B)          | `/dev:open-pr` (merged checklist + push + open)              |
| Open umbrella sub-PR/MR (Model C)           | inline in `/dev:develop` Step 6b (`references/multi-pr-template.md`) |
| Per-unit loop (Model C)                     | `/dev:develop` Step 6b (orchestration only)                  |
| Confluence publishing                       | `/common:confluence-update`                                  |
| Jira transitions                            | `/common:jira-update` (user-gated)                           |
| Finishing                                   | `superpowers:finishing-a-development-branch` (if installed)  |
