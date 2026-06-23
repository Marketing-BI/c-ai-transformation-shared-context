---
name: read-my-jira-tickets
description:
  Use whenever the user wants a quick overview of their own Jira tickets. Triggers on phrases like "what are my
  tickets", "show my jira tickets", "what am I working on", "what's on my plate", "where am I", "list my work",
  "my open tickets", "jaké mám tickety", "co mám v Jira", "na čem pracuji", "co mám na talíři",
  "zobraz moje tickety", "moje otevřené úkoly", or "/common:read-my-jira-tickets". Queries Jira via the Hub's
  Atlassian connector for all tickets assigned to the authenticated user, groups them by the status names returned
  by Jira (not a hardcoded list — handles any workflow including custom statuses), and prints a compact list with
  key, title, type, and updated date. For full detail on a ticket (description, priority, comments), hand off to
  /common:read-jira-ticket. This is the canonical way to surface the user's current Jira workload.
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
- "moje otevřené úkoly"
- "zobraz moje tickety"
- Any request for an overview of the _user's own_ assigned work

If the user asks about _someone else's_ tickets or wants a project-wide query, this is the wrong skill — use a
direct JQL search instead.

## How to fetch

### Step 1: Atlassian site (only if needed)

Hub Atlassian tools run against the connection's **active site** — you do not pass a `cloudId`. Usually the default
is correct, so just run the query. Only if the user works across multiple Atlassian sites and the default is wrong:
call `atlassian_list_sites` to see the options and
`atlassian_set_active_site` (with the target `cloud_id`) to switch.

### Step 2: Run the JQL query

Use `jira_search` with this JQL:

```
assignee = currentUser() AND statusCategory != Done ORDER BY status ASC, updated DESC
```

This returns all open work assigned to the authenticated user, ordered by status then most-recently-updated.

The connector returns a **fixed, compact projection per issue** — `key`, `summary`, `status` (display name),
`type` (issue type name), `assignee`, `updated`. There is no field selector, and **no `priority`, `description`,
`duedate`, or `sprint`** in the result. (JQL clauses like `statusCategory != Done` still filter correctly
server-side even though those fields aren't returned.) For a ticket's description, priority, or comments, the user
runs `/common:read-jira-ticket` on the specific key.

Pass an optional `limit` to cap the result set. If you cap it, say so in the output. If the user wants everything
including done work (e.g. "show me everything I've worked on"), drop the `statusCategory != Done` clause and add a
time bound like `updated >= -30d`.

## Output format

Group by the **status name returned by Jira** (the `status` field). Do not hardcode the status list, do not
normalise the names, do not translate — different Jira projects use different workflows and custom statuses
("Code Review", "Waiting for QA", "In Deployment", "Ready for Release", "Blocked by External", etc.). Whatever
status names come back are the group headers.

The result is already ordered by the JQL (`status ASC, updated DESC`), so render groups in the order their statuses
first appear and keep each group's returned order (most-recently-updated first).

The example below uses common status names for illustration — in the real output use whichever status names
actually appear in the user's Jira:

```
# My Jira tickets (N open)

## In Progress (M)
- **PROJ-123** [Story] Refactor auth middleware — updated 2d ago
- **PROJ-145** [Task] Add webhook retries — updated 5d ago

## Code Review (M)
- **PROJ-201** [Story] Order export endpoint — updated 1d ago

## To Do (M)
- ...
```

**Format rules:**

- Use the actual status names from Jira verbatim — no renaming, no grouping of similar-sounding statuses into one.
- `[Story]` / `[Task]` / `[Bug]` style type tag from the `type` field — short and scannable.
- Relative dates (`2d ago`, `3w ago`) for the updated field.
- Use English language for all output.
- If the user's tickets span 10+ distinct status names and the list gets noisy, still render them all but print a
  one-line heads-up at the top: _"This workflow has N distinct statuses — scroll for full breakdown."_

After the list, print a one-line summary like: _"N open tickets across P projects."_ (project derived from each key
prefix).

Then ask: _"Which one do you want to dig into?"_ — so the user can hand off to `/common:read-jira-ticket` for any
specific key (that's where description, priority, and comments come from).

## Edge cases

- **Zero tickets** — just say "No open Jira tickets assigned to you." Don't pad.
- **Auth failure / no Atlassian access** — surface the MCP error directly. Don't fabricate ticket data.
- **Wrong active site** — if results look wrong (or empty) and the user uses multiple sites, switch with
  `atlassian_set_active_site` (see Step 1) and re-run.
- **User asks for filtering** ("just project X", "only this sprint") — adjust the JQL accordingly. Common
  refinements: `priority in (Highest, High)`, `project = X`, `sprint in openSprints()`, `labels = "..."`. The filter
  applies server-side even though the matched fields aren't in the returned projection.
- **User asks to sort/flag by priority or due date** — those fields aren't in the list projection; tell the user and
  point them to `/common:read-jira-ticket` for a specific ticket, or refine the JQL to filter by them.
- **Huge backlogs** (lots of open tickets) — pass a `limit`, render what you show, and tell the user the list was
  capped and how to narrow (by project, sprint, or priority via JQL).

## Why this skill exists

The default Jira UI is slow to scan and the user often just wants a one-screen answer to "what am I working on?".
Producing this list reliably from JQL — grouped by status, in the order that matters — turns "open Jira, click
filter, scroll" into a single glance in chat. Per-ticket depth (description, priority, comments) is one
`/common:read-jira-ticket` away.
