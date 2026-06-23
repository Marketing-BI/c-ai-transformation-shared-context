---
name: context-validate
description: Check the health of a context index — the navigation page that points to where a team's information lives. Use this whenever someone wants to audit, lint, or review their knowledge index or router page for problems such as dead links, missing descriptions, entries in the wrong section, duplicates, or pages that have drifted out of date. Triggers on phrases like "check the context index", "audit our knowledge map", "are the links still good", "lint the router", "skontroluj rozcestník", "over odkazy v indexe". Read-only — it reports problems and suggests fixes, it does not change anything.
---

# Check a context index

Audit a navigation index and report what needs attention. **Read-only**: list real problems and suggest fixes, but change nothing — the owner decides what to act on.

## Load the index
Get the index the same two ways as `context-create`: the **`context__get_index` tool** if available, otherwise ask for the **URL**. Start from the top page.

## Go deep — dispatch explore agents
Don't just skim the top page. **Walk the whole tree, into the linked pages.** For coverage and speed, **dispatch one explore subagent per top-level branch / sub-page** (in parallel). Each agent: opens every link in its branch, follows sub-pages to the bottom, reads what's actually on each target, and returns concrete findings for that branch. Then merge.

Each agent (and you) checks for:

- **Dead links** — returns "not found" / moved / deleted. Flag with the exact link.
- **Empty or non-navigable targets** — the page opens but has no real content, or it's a landing that leads nowhere (a dead end where a reader can't continue). Flag the exact link.
- **Missing / placeholder entries** — no description, or still marked `needs link`.
- **Description accuracy** — does the one-line description **match what's actually on that target page** (i.e. "what you'll find there")? Verify against the real content.
- **Wrong section / duplicates** — an entry clearly under the wrong area, or the same destination (same link) listed twice.
- **Structure** — top page should stay short; flag a branch grown big enough to deserve its own sub-page.

## ⚠️ Don't invent problems — and don't churn
This is the most important rule. Only report **genuine, factual** issues:

- A description is fine **if it correctly says what's on the target** — even if you personally would word it differently. **Never** suggest stylistic rewrites ("could be phrased better", "make it punchier"). That is not a finding.
- Flag a description **only** when it is **factually wrong, missing, or genuinely insufficient** (doesn't tell the reader what's there). When you do, say *what is wrong* (e.g. "describes X but the page is about Y", "no description"), not how you'd rewrite it.
- **Be idempotent.** If nothing changed on the sources, a re-run days later must produce the **same result** — a clean index stays clean. Don't manufacture new nitpicks each run.

## Access-denied ≠ broken
If a link returns "access denied" or the auditor has no account, it is **not** a dead link — mark it **"unverified (no access)"**, don't flag it, don't guess its content, never try to log in.

## Report
A short, grouped list: what the problem is, the **exact link/location**, and the suggested fix. If the index is healthy, say so plainly (don't pad with style suggestions). The owner applies fixes or runs `context-create` to update an entry.
