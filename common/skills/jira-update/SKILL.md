---
name: jira-update
description:
  Use whenever work progresses on a Jira ticket and the ticket needs to reflect that. Triggers when the user starts
  or completes a task, opens or merges a PR/MR, hits a blocker, or logs time. Phrases like "update the Jira
  ticket", "log this in Jira", "move the ticket to", "add a Jira comment", "transition the ticket",
  "aktualizuj Jira tiket", "přesuň tiket do", "přidej komentář do Jira", "zaloguj do Jira", "změň stav tiketu",
  or "/common:jira-update". Enforces status transition discipline and comment standards (one per day,
  delivery-focused). This is the canonical way to keep Jira accurate as the
  delivery audit trail.
---

# Jira Update

Keep the Jira ticket accurate as work progresses. Jira is the delivery audit trail — status, comments, and links
should reflect reality at all times so anyone looking at the ticket knows exactly where things stand without asking.

## When to use

Update the relevant Jira issue whenever you:

- Start or complete a task
- Change the status of a ticket
- Open or merge a pull request / merge request
- Hit a blocker or dependency
- Log time worked

## How to run

### Step 1 — Transition the status

Move the ticket to the correct status based on where work is. The exact transitions available depend on the
project's workflow — always retrieve them first rather than guessing:

Use `mcp__claude_ai_Connectivity_Hub__atlassian__jira_get_transitions` to retrieve valid transitions from the
current status, then `mcp__claude_ai_Connectivity_Hub__atlassian__jira_transition_issue` to apply the change.

Common transition patterns (your project's workflow may differ):

| When | Typical target status |
|---|---|
| When you start work | `In Progress` (or equivalent active status) |
| When a PR/MR is opened | `In Review` / `Code Review` / `QA` (whichever your workflow uses) |
| When the PR/MR is approved | `Ready to Deploy` / `Stage & Deploy` (done by human operator in many workflows) |
| When the PR/MR is merged and deployed | `Done` / `Closed` |

Always use `jira_get_transitions` to confirm which transitions are valid from the ticket's current status —
do not assume transition names.

### Step 2 — Add a comment (if needed)

Add **at most one comment per day per ticket**. A comment is needed when there is meaningful progress to report —
not for every minor action. When adding a comment, include:

- A plain-language summary of what was achieved since the last comment — describe the features or changes in terms
  a product manager or non-technical reader can understand (e.g. "Added support for filtering results by date
  range" not "feat: add date_range filter — commit abc1234")
- Estimated % completion of the planned feature work
- Any blockers or open questions
- Link to the relevant PR/MR (not individual commit IDs)

Do **not** include raw commit messages or commit hashes — they are noise to anyone who is not in the code.
Keep comments factual and concise — they are the delivery audit trail, not a personal log.

Use `mcp__claude_ai_Connectivity_Hub__atlassian__jira_add_comment`.

### Step 3 — Associate PRs/MRs and note dependencies

- Use the branch naming convention (`<type>/<ticket-id>-<desc>`) to auto-link PRs/MRs where your git host supports
  it — this is the primary way work gets associated with the ticket.
- The Hub's Atlassian tools cannot create Jira issue links (`blocks` / `is blocked by` / `relates to`). When a
  dependency exists, state it explicitly in the Step 2 comment (referencing the other ticket key); create the link
  manually in the Jira UI if it needs to be visible there.

## Edge cases and failure modes

- **Ticket not found** — surface the MCP error; never update the wrong ticket.
- **Transition not available** — call `jira_get_transitions` to list what is valid from the current status;
  do not guess transition names.
- **Already commented today** — if a comment was added earlier today, update or append to it rather than creating
  a second one.
- **Blocked ticket** — note the blocking ticket key in the comment. Jira issue links can't be created via the Hub,
  so add the link manually in the Jira UI if it needs to appear there.

## Why this skill exists

Tickets that lag behind reality cause coordination failures — teammates assume work is not started when it is, or
done when it is blocked. This skill exists to make Jira updates a disciplined, consistent habit with a clear
comment format and transition path so the ticket always tells the truth.
