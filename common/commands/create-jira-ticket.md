---
description: Create a single Jira ticket via Atlassian MCP, with a preview gate before creation. Use for: "create ticket", "new Jira issue", "add task", "vytvoř ticket", "nový Jira úkol", "/common:create-jira-ticket".
argument-hint: [optional short description of the ticket]
---

# Command: create-jira-ticket

Create one Jira ticket conversationally, with a preview gate before the MCP call. $ARGUMENTS

## Prerequisite

Requires the **Atlassian MCP** configured and exposing:

- `createJiraIssue` (write)
- `atlassianUserInfo` (read, for assignee resolution)
- `getTransitionsForJiraIssue` (read, for status transition)
- `transitionJiraIssue` (write, for setting TO-DO status)

If any are missing, stop with a clear error naming the missing tool.

## Inputs

Resolve in order. Prompt the user for anything missing — one question at a time. No config file, no env vars, no caching. Ask every run.

| Field | Required | Notes |
|---|---|---|
| `cloudId` | yes | Site UUID or site URL. |
| `project` | yes | Project key (e.g. `PROJ`). If `parent` is provided, derive from its prefix (`PROJ-42` → `PROJ`) and skip the prompt; otherwise ask. |
| `issueType` | yes | Story, Task, Bug, Epic, Sub-task. |
| `summary` | yes | Short title. |
| `description` | yes | Markdown input; convert to ADF before send. |
| `assignee` | auto | **Auto-resolved** to current user via `atlassianUserInfo`. Do not ask — always assign to the current user. |
| `storyPoints` | no | Numeric value. Written to your Jira's Story Points custom field — its ID is instance-specific (e.g. `customfield_XXXXX`); configure your project's actual Story Points field ID, or discover it from the issue field metadata. Do not assume another instance's ID. For marker syntax and placement rules (used by batch workflows), see `/common:jira-estimates`. |
| `priority` | no | e.g. High, Medium, Low. |
| `labels` | no | Array of strings. |
| `parent` | no | Epic key for a Story; Story key for a Sub-task. |
| `additionalFields` | no | Object passed through verbatim to the MCP tool. |

## Flow

1. Gather missing required fields (ask one at a time). If `parent` is provided, derive `project` from its key prefix (`PROJ-42` → `PROJ`) and do not prompt for it.
2. **Resolve assignee.** Call `atlassianUserInfo` to get the current user's accountId. Always assign to the current user.
3. Convert `description` markdown → ADF using the mapping table below.
4. If `storyPoints` provided, include it in `additionalFields` using your Jira instance's Story Points field ID (instance-specific; discover via issue field metadata if unknown).
5. Render the preview block (see "Preview Format"). Wait for the user to respond `yes` / `create` (or `edit` / `cancel`).
6. Call `createJiraIssue` with the resolved fields.
7. **Transition to TO-DO.** Call `getTransitionsForJiraIssue` to find the transition ID for "To Do" status, then call `transitionJiraIssue` to move the ticket to TO-DO. If the transition fails (e.g. already in TO-DO), log a warning and continue.
8. Return: issue key + browse URL + status (TO-DO).

### Preview Format

```
Ticket Preview
──────────────
Site:        <cloudId>
Project:     <project>
Type:        <issueType>
Summary:     <summary>
Assignee:    <current user name> (auto)
Priority:    <priority or "-">
Labels:      <labels or "-">
Parent:      <parent or "-">
SP:          <storyPoints or "-"> (instance-specific Story Points field)
Additional:  <keys of additionalFields or "-">

Description (rendered from markdown):
<first ~20 lines; truncate with "… (N more lines)">

Create this ticket? (yes / edit / cancel)
```

## Dry-Run

If the user says `preview only`, `don't create, just show me`, or equivalent: run up to the preview, then stop without calling `createJiraIssue`.

## Batch Mode (invoked from a plan-to-tickets workflow)

When this command is invoked as part of a batch ticket-creation workflow, the orchestrator has already shown the user a consolidated batch preview and received explicit confirmation for the whole set. In that context:

- **Skip step 5 (the per-ticket preview block)** — do NOT ask for yes/edit/cancel again.
- Still run steps 1–4 (gather/resolve fields, assignee resolution, markdown→ADF, SP field) and steps 6–7 (call `createJiraIssue`, transition to TO-DO).
- Still surface MCP errors verbatim. Do not swallow failures to keep the batch going — return control to the orchestrator.
- Recognize you're in batch mode when the invoking context explicitly says so (e.g. "batch already confirmed, skip preview"). Do not infer batch mode from a large number of tickets — the caller must be explicit.

## Error Handling

- Surface MCP errors verbatim, highlighting the offending field.
- Suggest a likely fix (`assignee accountId not found → try email lookup`, `invalid issueType 'story' — case matters, try 'Story'`).
- No silent retries. No fallback to a different tool.

## Out of Scope

Comments, attachments, bulk creation. Do not attempt to work around these limitations with clever MCP calls — refuse and suggest a separate workflow. Note: the TO-DO transition is built into this command's flow (step 7).

---

## Markdown → ADF Conversion

ADF (Atlassian Document Format) is required for Jira description fields.

### Envelope

```json
{ "type": "doc", "version": 1, "content": [ /* block nodes */ ] }
```

### Block Nodes

| Markdown | ADF node |
|---|---|
| `# H1` … `###### H6` | `{ "type": "heading", "attrs": { "level": 1-6 }, "content": [text] }` |
| Paragraph | `{ "type": "paragraph", "content": [text] }` |
| Bullet list `- item` | `{ "type": "bulletList", "content": [{ "type": "listItem", "content": [paragraph] }] }` |
| Numbered list `1. item` | `{ "type": "orderedList", "content": [{ "type": "listItem", "content": [paragraph] }] }` |
| Fenced code block ` ```lang ` | `{ "type": "codeBlock", "attrs": { "language": "lang" }, "content": [{ "type": "text", "text": "..." }] }` |
| Blockquote `> text` | `{ "type": "blockquote", "content": [paragraph] }` |
| Horizontal rule `---` | `{ "type": "rule" }` |

### Inline Marks

| Markdown | ADF mark |
|---|---|
| `**bold**` | `{ "type": "strong" }` |
| `*italic*` / `_italic_` | `{ "type": "em" }` |
| `` `code` `` | `{ "type": "code" }` |
| `~~strike~~` | `{ "type": "strike" }` |
| `[text](url)` | `{ "type": "link", "attrs": { "href": "url" } }` |

Applied as: `{ "type": "text", "text": "word", "marks": [{ "type": "strong" }] }`.

### Degradation

Anything not in the tables above → render as a plain `paragraph` of `text` with no marks. Do not emulate tables, panels, mentions, or emoji. Lossy-but-readable, not pixel-perfect.
