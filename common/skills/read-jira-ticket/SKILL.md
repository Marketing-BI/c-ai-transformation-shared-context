---
name: read-jira-ticket
description:
  Use whenever the user wants to read, load, fetch, open, or get context from a Jira ticket by its key (formats like
  PROJ-123, FEAT-456, OPS-789). Pulls ticket context via Atlassian MCP — description, recent comments (last 10 by
  default, or all/filtered on request), every attachment (downloads videos and transcribes them via whisper if
  available), linked Jira tickets, and any Confluence pages referenced in the ticket or its comments. Trigger this
  skill even when the user just mentions a ticket key with intent to discuss, plan, or implement work related to it
  ("look at PROJ-500", "what's in FEAT-12", "/common:read-jira-ticket PROJ-9"). The user typically passes the ticket
  key as an argument or mentions it inline. This is the canonical way to load Jira context before any work tied to a
  ticket — do not try to summarize a ticket from memory or guess its content.
  Triggers: "read ticket", "load ticket", "fetch jira ticket", "open jira issue", "get ticket context",
  "načti ticket", "otevři Jira tiket", "zobraz tiket", "načti Jira issue", "co je v tiketu", "/common:read-jira-ticket"
---

# Read Jira Ticket

Load a Jira ticket completely so the user (and you) have full context before discussing or implementing anything
related to it. A ticket is the source of truth for _what_ and _why_ — and the linked Confluence pages and video
attachments often hold context the comments only refer to indirectly. Pulling everything up-front prevents the
back-and-forth of "wait, what did the ticket say?".

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

## Comment scope overrides

The default is the **last 10 comments**. Override when any of these apply:

- **User explicitly asks** — "all comments", "full history", "every comment", "load comment thread in full", "fetch
  all" → fetch all.
- **User specifies a number** — "last 20 comments", "first 5 comments", "only last 3" → use their number.
- **User asks for a date range** — "comments from this week", "comments since <date>" → filter by timestamp.
- **User references a specific author** — "what did <person> say" → return all comments by that author (regardless
  of count).
- **Ticket has < 10 comments** — fetch all (there's nothing to trim).
- **Ticket is small overall** (short description, few attachments, < 20 comments total) — fetch all; the token
  saving is negligible and context cost of missing something is higher.

When trimming to the default 10, **always include the first comment** too if the ticket has more than 10. The
opening comment often contains the initial problem statement or clarifying question that sets the thread context.
Label it clearly in the output.

## What to fetch

For the given key, gather all of:

1. **Core ticket fields** — summary, description, status, issue type, assignee, reporter, priority, labels, sprint,
   fix versions
2. **Comments** — by default, the **last 10 comments** chronologically (newest last, so the most recent context is
   most visible). If the ticket has fewer than 10, fetch all. Older comments are skipped but their count is shown in
   the output so the user knows what was omitted. The user can override this default (see _Comment scope overrides_
   above).
3. **Attachments** — every file; for videos, download and transcribe (see Step 4)
4. **Linked Jira tickets** — issue links (epic, blocks, relates to, duplicates) and parent
5. **Linked Confluence pages** — fetch every Confluence URL referenced in the description, comments, or remote links

## How to fetch

### Step 1: Discover the Atlassian site

If you don't already know the cloud ID, call `mcp__atlassian__getAccessibleAtlassianResources` first. If it
returns more than one site, ask the user which one before proceeding — never silently pick.

### Step 2: Fetch the ticket

Call `mcp__atlassian__getJiraIssue` with the ticket key and cloud ID. The response contains the description,
comments (`fields.comment.comments`), attachments (`fields.attachment`), and basic issue links
(`fields.issuelinks`).

For comments, apply the scope rules from _Comment scope overrides_:

- Default: slice to the **last 10** from `fields.comment.comments` (array is chronological, oldest first — so take
  `.slice(-10)`).
- If total count > 10, also keep `fields.comment.comments[0]` (the first comment) for context.
- Record the total count (`fields.comment.total`) so the output can show `"Showing 10 of 47 comments"`.

If the MCP response paginates comments, fetch only the last page by default. Fetch earlier pages only when an
override from _Comment scope overrides_ applies.

### Step 3: Fetch remote links

Call `mcp__atlassian__getJiraIssueRemoteIssueLinks` to get external links registered on the ticket. Confluence
pages are most commonly attached this way.

### Step 4: Process attachments

For each entry in `fields.attachment`, branch on the MIME type / extension:

- **Image** (`image/*`, `.png`/`.jpg`/`.jpeg`/`.gif`/`.webp`) — fetch via `mcp__atlassian__fetch` and view with
  the Read tool so you can describe the visual content. If the user only needs to know images exist, just list
  filename + URL.
- **PDF / text / markdown / log** — fetch via `mcp__atlassian__fetch` and include the content (or summary if very
  long).
- **Video** (`video/*`, `.mp4`/`.mov`/`.webm`/`.mkv`/`.avi`):
  1. Download the file from the attachment's `content` URL into a temp directory
     (e.g. `/tmp/jira-<ticket>-<filename>`). Use `mcp__atlassian__fetch` if it returns binary content correctly;
     otherwise use curl with the user's auth via the MCP-provided URL.
  2. Probe for transcription tooling: `which whisper` and `which ffmpeg`. Don't assume they exist — they often
     won't.
  3. **If `whisper` is available**: run `whisper <file> --output_format txt --language auto --model base`, read the
     resulting `.txt`, and include the transcript inline (collapsed under a heading if long).
  4. **If `whisper` is missing**: try to extract metadata with `ffprobe` (duration, resolution) if available. Then
     output the filename, size, duration if known, and the URL — and tell the user explicitly: "Video transcription
     is not available on this machine (no `whisper` CLI). Open the video manually: <URL>." Do not invent a
     transcript or guess at content.
- **Other binary** (zip, archives, office docs) — list filename, size, URL; don't try to extract unless the user
  asks.

### Step 5: Follow Confluence links

Confluence URLs come from two places:

- Remote links from Step 3
- URLs embedded in the description and comment text — match patterns like
  `*.atlassian.net/wiki/spaces/.../pages/<ID>/...`

For each URL, extract the page ID (the numeric segment after `/pages/`) and call
`mcp__atlassian__getConfluencePage`. Also fetch footer/inline comments via
`mcp__atlassian__getConfluencePageFooterComments` and `mcp__atlassian__getConfluencePageInlineComments` when they
likely contain decision context (e.g. ticket comments reference "see Confluence comment").

If you find more than 5 distinct Confluence pages, list them and ask the user which to fetch — don't silently pull
all of them, since each can be large.

### Step 6: Follow linked Jira tickets (lightly)

For each entry in `fields.issuelinks` and the `parent` field, list the linked key + summary + status + link type.
**Do not** recursively fetch linked tickets unless the user asks — that explodes context fast. If the user wants
depth, they'll say so.

## Output format

Present the loaded context using this structure. Use English for all output.

    # [TICKET-KEY] Title

    **Status:** … | **Type:** … | **Priority:** …
    **Assignee:** … | **Reporter:** …
    **Sprint:** … | **Labels:** …, …

    ## Description
    <full description, preserving formatting>

    ## Comments (showing N of M)

    <!-- If trimmed to default 10 and total > 10: show the first comment separately,
         then a skip-indicator, then the last 10. Otherwise show all comments in order. -->

    **[First comment — Author — YYYY-MM-DD HH:MM]**
    <body>

    _… N earlier comments skipped. Ask to load them if needed. …_

    **[Author — YYYY-MM-DD HH:MM]**
    <body>

    **[Author — YYYY-MM-DD HH:MM]**
    <body>
    …

    ## Attachments (N)
    - `filename.ext` (type, size) — <inline content / transcript / "manual review needed: URL">

    ## Linked Jira tickets
    - **KEY-NNN** (link type) — title — status

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
- **Confluence page in a space the user can't see** — note the URL and the access error, move on.
- **Very large ticket** (100+ comments) — the default scope (last 10 + first) handles this gracefully; the user
  can then ask "load comments 11–50" or "show me the full thread" to drill in. Do not auto-fetch everything — that
  defeats the scope default.
- **Decision buried in older comments** — if the last 10 reference an older decision (e.g. "as discussed above" or
  "per my earlier comment"), flag it explicitly in the output and offer to fetch more: _"Comment 8 references an
  earlier decision. Want me to load older comments?"_
- **Video without whisper** — be explicit about the gap. The user needs to know the video content was not loaded so
  they don't assume you've seen it.
- **Multiple ticket keys in the prompt** — ask which one rather than fetching all; loading multiple tickets at once
  usually means the user actually wanted a JQL search, which is a different task.

## Why this skill exists

Most Jira-related work fails not because the implementation is hard but because the implementer missed a constraint
buried in comment 14, or a design decision in a linked Confluence page, or a bug repro in an attached video. This
skill exists to remove that failure mode by loading everything in one disciplined pass — and by being explicit when
something (like a video) can't be loaded, so the user knows what's still missing.
