# Decision Tree — develop quick reference

Visual map of the full cycle. Each step links back to its full section in `SKILL.md`.

```
develop invoked
    │
    ▼
Step 0: Validate source ($1)
    ├─ Confluence URL? → Confluence loader
    ├─ Local .md path? → Read loader
    ├─ Jira key?       → /common:read-jira-ticket
    ├─ Inline desc?    → Use prompt as source
    └─ None?           → STOP, ask user for any source
    │
    ▼
Step 1: Load all signals (source + Jira context + local repo state)
Step 2: Code-vs-source reconciliation table
    │
    ▼
Step 3: Brainstorm?  (DEFAULT = ON)
    ├─ Small + isolated change AND source rich AND clean reconciliation → SKIP, go to Step 4
    └─ Otherwise                                                         → brainstorm
                                                                           (superpowers:brainstorming if installed)
    │
    ▼
Step 4a: Ask user — Model A (worktree, single PR/MR) or Model B (multi-PR/MR split)?
Step 4b: Write plan (superpowers:writing-plans if installed) — per chosen model
    │
    ▼
Step 5: Git setup (see references/conventions.md for branch naming)
    ├─ Model A → worktree
    └─ Model B → umbrella + sub-branch
    │
    ▼
Step 6: Implement task by task, test-first (superpowers:subagent-driven-development /
    test-driven-development if installed); local commits via /common:git-commit
    │
    ▼
Step 7: PRE-PUSH local code review → delegate to /dev:code-review
    (it selects + dispatches the dev: reviewer agents in parallel and triages)
    Fix Critical + contract gaps; decide Recommendations w/ user;
    surface business-case Client Gaps / Open Questions
    │
    ▼
Step 7.5: Pre-PR/MR housekeeping — invoke /dev:pr-prep (NO create-PR/MR token)
    → does the worktree mutations open-pr is read-only about (its own
      SKILL.md lists them). Commit its changes on the current branch.
    │
    ▼
Step 8: Open the PR/MR — forks by delivery model
    Model A (single PR/MR) → delegate to /dev:open-pr
        → it pushes, builds the team-agreed body, requests the reviewer,
          and asks for the Jira key if it can't resolve one
    Model B (umbrella/multi-PR/MR) → open the sub-PR/MR HERE (not open-pr)
        8b base ref: umbrella, OR stacked on preceding PR/MR head if still open
        8c body ← references/multi-pr-template.md (open-pr format + series context)
        8d/e title `<TICKET> PR/MR <N>:` + push + create on your git host
        (pulls version/env/summary from Step 7.5; no reviewer/Jira field here)
    │
    ▼
Step 9 (Model B): Per-PR/MR loop — repeat 4–8 for next sub-PR/MR; final umbrella merge
Step 10: Finish — finishing-a-development-branch flow, Jira transitions, cleanup
```
