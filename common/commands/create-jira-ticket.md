---
description: Create a single Jira ticket via the Hub's Atlassian connector, with a preview gate before creation. Use for: "create ticket", "new Jira issue", "add task", "vytvoř ticket", "nový Jira úkol", "/common:create-jira-ticket".
argument-hint: [optional short description of the ticket]
---

# Command: create-jira-ticket

Create one Jira ticket conversationally, with a preview gate before the MCP call. $ARGUMENTS

## Prerequisite

Requires the **Hub's Atlassian connector** configured and exposing:

- `mcp__claude_ai_Connectivity_Hub__atlassian__jira_create_issue` (write)
- `mcp__claude_ai_Connectivity_Hub__atlassian__atlassian_user_info` (read, for assignee resolution)
- `mcp__claude_ai_Connectivity_Hub__atlassian__jira_get_transitions` (read, for status transition)
- `mcp__claude_ai_Connectivity_Hub__atlassian__jira_transition_issue` (write, for setting TO-DO status)

If any are missing, stop with a clear error naming the missing tool.

## Inputs

Resolve in order. Prompt the user for anything missing — one question at a time. No config file, no env vars, no caching. Ask every run.

| Field | Required | Notes |
|---|---|---|
| `project` | yes | Project key (e.g. `PROJ`) → tool param `project_key`. If `parent` is provided, derive from its prefix (`PROJ-42` → `PROJ`) and skip the prompt; otherwise ask. |
| `issueType` | yes | Story, Task, Bug, Sub-task → tool param `issue_type` (name or id). |
| `summary` | yes | Short title. |
| `description` | yes | Markdown — passed straight to the tool, which converts it to ADF. Do **not** hand-build ADF. |
| `assignee` | auto | **Auto-resolved** to current user via `atlassian_user_info` → passed as `assignee_account_id`. Do not ask — always assign to the current user. |
| `priority` | no | e.g. High, Medium, Low. |
| `labels` | no | Array of strings. |
| `parent` | no | Epic key for a Story; Story key for a Sub-task → tool param `parent_key`. |

> **Not supported by the Hub connector:** effort estimates and any other custom field — `jira_create_issue`
> only accepts `project_key`, `issue_type`, `summary`, `description`, `assignee_account_id`, `labels`, `priority`,
> `parent_key`. If a custom field (e.g. an effort-estimate field) is needed, set it manually in the Jira UI after creation.

The active Atlassian **site** is the connection's default — you do not pass a `cloudId`. If the user works across
multiple sites, switch once with `atlassian_set_active_site` before creating.

## Flow

1. Gather missing required fields (ask one at a time). If `parent` is provided, derive `project` from its key prefix (`PROJ-42` → `PROJ`) and do not prompt for it.
2. **Resolve assignee.** Call `atlassian_user_info` to get the current user's accountId; pass it as `assignee_account_id`. Always assign to the current user.
3. Render the preview block (see "Preview Format"). Wait for the user to respond `yes` / `create` (or `edit` / `cancel`).
4. Call `jira_create_issue` with the resolved fields (`project_key`, `issue_type`, `summary`, `description` as Markdown, `assignee_account_id`, and any of `priority`, `labels`, `parent_key`).
5. **Transition to TO-DO.** Call `jira_get_transitions` to find the transition ID for "To Do" status, then call `jira_transition_issue` to move the ticket to TO-DO. If the transition fails (e.g. already in TO-DO), log a warning and continue.
6. Return: issue key + browse URL + status (TO-DO).

### Preview Format

```
Ticket Preview
──────────────
Project:     <project>
Type:        <issueType>
Summary:     <summary>
Assignee:    <current user name> (auto)
Priority:    <priority or "-">
Labels:      <labels or "-">
Parent:      <parent or "-">

Description (Markdown, converted to ADF on create):
<first ~20 lines; truncate with "… (N more lines)">

Create this ticket? (yes / edit / cancel)
```

## Dry-Run

If the user says `preview only`, `don't create, just show me`, or equivalent: run up to the preview, then stop without calling `jira_create_issue`.

## Batch Mode (invoked from a plan-to-tickets workflow)

When this command is invoked as part of a batch ticket-creation workflow, the orchestrator has already shown the user a consolidated batch preview and received explicit confirmation for the whole set. In that context:

- **Skip step 3 (the per-ticket preview block)** — do NOT ask for yes/edit/cancel again.
- Still run steps 1–2 (gather/resolve fields, assignee resolution) and steps 4–5 (call `jira_create_issue`, transition to TO-DO).
- Still surface MCP errors verbatim. Do not swallow failures to keep the batch going — return control to the orchestrator.
- Recognize you're in batch mode when the invoking context explicitly says so (e.g. "batch already confirmed, skip preview"). Do not infer batch mode from a large number of tickets — the caller must be explicit.

## Error Handling

- Surface MCP errors verbatim, highlighting the offending field.
- Suggest a likely fix (`assignee accountId not found → look the person up with jira_lookup_account_id`, `invalid issueType 'story' — case matters, try 'Story'`).
- No silent retries. No fallback to a different tool.

## Out of Scope

Comments, attachments, bulk creation, and custom fields (incl. effort estimates — not settable via the Hub
connector). Do not attempt to work around these limitations with clever MCP calls — refuse and suggest a separate
workflow or a manual Jira edit. Note: the TO-DO transition is built into this command's flow (step 5).

Description content is passed as **Markdown** and converted to ADF by the connector — there is no manual ADF
construction in this command.
