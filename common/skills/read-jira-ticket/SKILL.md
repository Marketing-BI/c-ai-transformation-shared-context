---
name: read-jira-ticket
description:
  Use whenever the user wants to read, load, fetch, open, or get context from a Jira ticket by its key (formats like
  PROJ-123, FEAT-456, OPS-789). Pulls ticket context via the Hub's Atlassian connector — core fields, description,
  the recent comments the connector returns (rendered as Markdown), and any Confluence pages referenced in the
  ticket or its comments. Trigger this skill even when the user just mentions a ticket key with intent to discuss,
  plan, or implement work related to it ("look at PROJ-500", "what's in FEAT-12", "/common:read-jira-ticket PROJ-9").
  The user typically passes the ticket key as an argument or mentions it inline. This is the canonical way to load
  Jira context before any work tied to a ticket — do not try to summarize a ticket from memory or guess its content.
  Triggers: "read ticket", "load ticket", "fetch jira ticket", "open jira issue", "get ticket context",
  "načti ticket", "otevři Jira tiket", "zobraz tiket", "načti Jira issue", "co je v tiketu", "/common:read-jira-ticket"
---

# Read Jira Ticket

Load a Jira ticket so the user (and you) have full context before discussing or implementing anything related to
it. A ticket is the source of truth for _what_ and _why_ — and the linked Confluence pages often hold context the
comments only refer to indirectly. Pulling everything up-front prevents the back-and-forth of "wait, what did the
ticket say?".

## Inputs

The user provides a Jira ticket key. Resolve it in this order (mandatory — do not skip steps):

1. **Explicit argument** (primary, preferred): `/common:read-jira-ticket PROJ-123`.
2. **Inline in the message**: "read PROJ-123", "load FEAT-456", "what's in OPS-789", or any bare key. Extract with
   the pattern `[A-Z][A-Z0-9_]+-\d+`.
3. **Git branch fallback** (if the user forgot to pass a key): run `git branch --show-current` in the project
   directory and extract the ticket pattern from the branch name. Branches commonly embed the key —
   `feat/PROJ-720-checkout-flow`, `fix/FEAT-123-bug`, `PROJ-720-spike`, `chore/OPS-42-cleanup` all contain valid
   keys. Use the same regex as step 2.
4. **Ask** — if none of the above yield a key, ask the user which ticket they mean. Do not guess.

When you resolve the key via the git branch fallback (step 3), **always state it explicitly** before proceeding —
the user needs a chance to correct if the branch has the wrong key or points at a stale ticket:

> "No ticket key in the prompt — using `PROJ-720` from the current branch `feat/PROJ-720-checkout-flow`. Continuing
> unless you say otherwise."

If multiple candidate keys appear in a single source (the message mentions two tickets, or the branch name contains
two patterns), ask which one the user meant rather than picking one.

## Comments

`jira_get_issue` returns the ticket's **recent comments** already rendered as Markdown (newest first), capped by the
connector. That returned set is what you work with — the Hub connector does not expose comment pagination, totals,
server-side author/date filtering, or full-history retrieval. So:

- Present all comments the connector returns, oldest-to-newest in the output, so the most recent context reads last.
- If a returned comment refers to an earlier decision that isn't in the returned set ("as discussed above", "per my
  earlier comment"), say so explicitly and point the user to the Jira UI for the full thread — you cannot fetch
  older comments through the Hub.
- If the user needs the complete comment history, author-filtered comments, or a specific date range, tell them that
  isn't available via the Hub connector and they should open the ticket in Jira directly.

## What to fetch

For the given key, gather:

1. **Core ticket fields** — key, summary, status, issue type, priority, assignee, reporter, labels, created,
   updated, and the browse URL (all returned by `jira_get_issue`).
2. **Description** — returned as Markdown.
3. **Comments** — the recent comments returned by `jira_get_issue` (see _Comments_ above).
4. **Linked Confluence pages** — every Confluence URL referenced in the description or comment text.

> The Hub's Atlassian connector does **not** return attachments, remote links, or Jira issue links, and provides no
> way to download attachment files. If the user needs an attached file, a video, or the linked-issue graph, point
> them to the ticket in Jira — those aren't reachable through the Hub.

## How to fetch

### Step 1: Atlassian site (only if needed)

Hub Atlassian tools run against the connection's **active site** — you do not pass a `cloudId`. Usually the default
is correct, so just call the tools. Only if the user works across multiple Atlassian sites and you need a different
one: call `atlassian_list_sites` to see the options and
`atlassian_set_active_site` (with the target `cloud_id`) to switch. If a
call fails because the wrong site is active, switch and retry.

### Step 2: Fetch the ticket

Call `jira_get_issue` with `issue_key: <TICKET>`. The response is a
curated object: `key`, `summary`, `status`, `type`, `priority`, `assignee`, `reporter`, `labels`, `created`,
`updated`, `url`, `description` (Markdown), and `comments` (recent, each with `author`, `created`, `body` in
Markdown). There is no `cloudId`, `fields` selector, attachment, or issue-link data.

### Step 3: Follow Confluence links

Scan the `description` and every comment `body` for Confluence URLs — match patterns like
`*.atlassian.net/wiki/spaces/.../pages/<ID>/...`. For each, extract the page ID (the numeric segment after
`/pages/`) and call `confluence_get_page` with `page_id: <ID>`. When a
page likely carries decision context discussed on the ticket (e.g. a comment says "see the Confluence comment"),
also fetch its comments via `confluence_get_page_comments` (one call
returns footer and inline comments).

If you find more than 5 distinct Confluence pages, list them and ask the user which to fetch — don't silently pull
all of them, since each can be large.

## Output format

Present the loaded context using this structure. Use English for all output.

    # [TICKET-KEY] Title

    **Status:** … | **Type:** … | **Priority:** …
    **Assignee:** … | **Reporter:** …
    **Labels:** …, … | **Updated:** …

    ## Description
    <full description, preserving formatting>

    ## Comments (N returned)
    <!-- All comments the connector returned, oldest-to-newest. Note if older comments exist but weren't returned. -->

    **[Author — YYYY-MM-DD HH:MM]**
    <body>

    **[Author — YYYY-MM-DD HH:MM]**
    <body>
    …

    ## Linked Confluence pages
    ### <Page title>
    <page content or summary>

After the structured output, ask one short follow-up: _"What would you like to do with this ticket?"_ — so the
user can direct the next step (plan, implement, summarize for someone else, etc.) without you presuming.

## Edge cases and failure modes

- **Ticket not found** — surface the exact MCP error. Suggest checking the ticket key spelling. Never fabricate
  ticket content.
- **Permission denied** — tell the user their Atlassian account may lack access to this project. Stop; don't
  partial-fetch around it.
- **Wrong active site** — if a call fails because the active site doesn't hold the ticket, switch with
  `atlassian_set_active_site` (see Step 1) and retry.
- **Confluence page in a space the user can't see** — note the URL and the access error, move on.
- **Decision buried in older comments** — the connector only returns a recent window; if a returned comment
  references an earlier decision that isn't present, flag it and point the user to the Jira UI for the full thread.
- **Attachment / linked-issue context needed** — the Hub can't reach attachments, remote links, or issue links. Say
  so and point the user to the ticket in Jira rather than pretending to have loaded them.
- **Multiple ticket keys in the prompt** — ask which one rather than fetching all; loading multiple tickets at once
  usually means the user actually wanted a JQL search, which is a different task.

## Why this skill exists

Most Jira-related work fails not because the implementation is hard but because the implementer missed a constraint
buried in a comment or a design decision in a linked Confluence page. This skill exists to remove that failure mode
by loading the ticket and its referenced Confluence context in one disciplined pass — and by being explicit about
what the Hub connector can't reach (attachments, issue links, full comment history), so the user knows what's still
only in Jira.
