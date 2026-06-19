---
name: read-my-jira-tickets
description:
  Use whenever the user wants a quick overview of their own Jira tickets. Triggers on phrases like "what are my
  tickets", "show my jira tickets", "what am I working on", "what's on my plate", "where am I", "list my work",
  "my open tickets", "jaké mám tickety", "co mám v Jira", "na čem pracuji", "co mám na talíři",
  "zobraz moje tickety", "moje otevřené úkoly", or "/common:read-my-jira-tickets". Queries Jira via Atlassian MCP
  for all tickets assigned to the authenticated user, groups them by the actual status names returned by Jira (not
  a hardcoded list — handles any workflow including custom statuses), and prints a compact list with key, title,
  status, priority, updated date, and a one-sentence summary of each ticket's description. This is the canonical
  way to surface the user's current Jira workload.
---

# Read My Jira Tickets

Give the user a fast, scannable snapshot of every Jira ticket currently assigned to them, grouped by status. The
point is to answer "what am I working on right now?" without the user having to open Jira and apply filters.

## When to use

Trigger on any of:

- "what are my tickets"
- "show my jira tickets" / "my jira tickets"
- "what am I working on"
- "what's on my plate"
- "where am I"
- "list my work"
- "my open tickets"
- "jaké mám tickety" / "moje Jira tickety"
- "co mám v Jira" / "co mám na talíři"
- "na čem pracuji" / "co teď řeším"
- Any request for an overview of the _user's own_ assigned work

If the user asks about _someone else's_ tickets or wants a project-wide query, this is the wrong skill — use a
direct JQL search instead.

## How to fetch

### Step 1: Discover the Atlassian site

Call `mcp__atlassian__getAccessibleAtlassianResources` to get the cloud ID. If the user has more than one
accessible site, ask which one — don't pick silently.

### Step 2: Run the JQL query

Use `mcp__atlassian__searchJiraIssuesUsingJql` with this JQL:

```
assignee = currentUser() AND statusCategory != Done ORDER BY status ASC, updated DESC
```

This returns all open work assigned to the authenticated user, ordered by status then most-recently-updated.

Request these fields explicitly to keep the response small and the output useful:
`summary, description, status, priority, issuetype, updated, duedate, project, sprint`

The `status` field must include both `name` and `statusCategory` — you need `fields.status.name` (the display name
used for grouping) and `fields.status.statusCategory.key` (used for ordering groups: `indeterminate` active work
first, then `new` not-started, then any other categories).

The `description` field is used to produce a one-sentence summary in the output (see Output format). If Jira
returns the description in ADF (Atlassian Document Format), extract the plain text before summarising.

If the user asks for _everything including done_ (e.g. "show me everything I've worked on"), drop the
`statusCategory != Done` clause and add a sensible time bound like `updated >= -30d`.

### Step 3: Handle pagination

If the response indicates more results than returned (check `total` vs `issues.length`), paginate with `startAt`
until you have everything — but cap at ~50 issues. If there are more than 50, tell the user the count and ask
whether to narrow by project, sprint, or priority.

## Output format

Group by the **actual status name returned by Jira** (from `fields.status.name`). Do not hardcode the status list,
do not normalise the names, do not translate — different Jira projects use different workflows and custom statuses
("Code Review", "Waiting for QA", "In Deployment", "Ready for Release", "Blocked by External", etc.). Whatever
status names come back from the API are the group headers.

**Ordering of status groups** — sort by `fields.status.statusCategory.key` so active work surfaces first, then by
status name alphabetically within each category:

1. `indeterminate` category ("In Progress" and anything derived — active work)
2. `new` category ("To Do", "Open", "Backlog" and similar — not started)
3. Anything else that appears (custom categories, e.g. some projects separate "Blocked" into its own category)

Within each status group, sort by priority (Highest → Lowest), then most recently updated.

Each ticket line is followed by a **one-sentence summary** of its description — short, grounded in what the ticket
actually says. See the rules below.

The example below uses common status names for illustration — in the real output you use whichever status names
actually appear in the user's Jira:

```
# My Jira tickets (N open)

## In Progress (M)
- **PROJ-123** [P1] Refactor auth middleware — updated 2d ago
   _Migrates the legacy session flow to the new token-based middleware._
- **PROJ-145** [P2] Add webhook retries — updated 5d ago
   _Adds idempotent retries for outbound webhook delivery failures._

## Code Review (M)
- **PROJ-201** [P1] Order export endpoint — updated 1d ago
   _(no description)_

## Waiting for QA (M)
- ...

## To Do (M)
- ...

## Blocked (M)
- ...
```

**Description summary rules:**

- **One sentence, max ~100 characters.** The goal is "what is this ticket about?" in a glance — not a recap.
- **Grounded in the description only.** The summary must be derivable from what the ticket literally says. No
  brainstorming, no solutioning, no inferring intent beyond the text. If the description says "Migrate JWT to
  session middleware. Existing tokens must stay valid.", a valid summary is
  _"Migrates JWT auth to session-based middleware."_ It is not
  _"Authentication refactor to improve security."_
- **Empty description** — render `_(no description)_`. Do not invent a summary from the title.
- **Very short description** (already one sentence, ≤100 chars) — use it verbatim.
- **Formatting** — strip ADF formatting (bold, italic, links, code blocks) to plain text before summarising. Do not
  quote formatting markers in the summary line.
- If the user wants full, formatted context of a specific ticket, they run `/common:read-jira-ticket` on that key.

**Other format rules:**

- Use the actual status names from Jira verbatim — no renaming, no grouping of similar-sounding statuses into one.
- If the user's tickets span 10+ distinct status names and the list gets noisy, still render them all but print a
  one-line heads-up at the top: _"This workflow has N distinct statuses — scroll for full breakdown."_
- `[P1]` style priority tag — short, scannable. Skip if priority is None/Unassigned.
- Relative dates (`2d ago`, `3w ago`) for the updated field; absolute date for due dates if present and within 14
  days, prefixed with ⚠ if overdue.
- Use English language for all output.

After the list, print a one-line summary like: _"N open tickets across P projects. M overdue, K due this week."_

Then ask: _"Which one do you want to dig into?"_ — so the user can hand off to `/common:read-jira-ticket` for any
specific key.

## Edge cases

- **Zero tickets** — just say "No open Jira tickets assigned to you." Don't pad.
- **Auth failure / no Atlassian access** — surface the MCP error directly. Don't fabricate ticket data.
- **Multiple Atlassian sites** — ask the user which site, or offer to run the query against all and merge.
- **User asks for filtering** ("just the urgent ones", "only project X") — adjust the JQL accordingly. Common
  refinements: `priority in (Highest, High)`, `project = X`, `sprint in openSprints()`, `labels = "..."`.
- **Huge backlogs** (>200 open) — don't try to render them all. Show a summary by project/status and ask how to
  narrow.

## Why this skill exists

The default Jira UI is slow to scan and the user often just wants a one-screen answer to "what am I working on?".
Producing this list reliably from JQL — grouped by status, sorted by what matters, with a grounded one-sentence
summary per ticket — turns "open Jira, click filter, scroll" into a single sentence in chat.
