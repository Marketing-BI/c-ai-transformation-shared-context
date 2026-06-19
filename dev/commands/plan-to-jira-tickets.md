---
description: |
  Create Stories + Sub-tasks under an existing Jira Epic from an implementation plan (a Confluence page or a local
  markdown file), with estimates populated. Never creates Epics. Use for: "plan to jira", "create tickets from plan",
  "break the plan into tickets", "plán do jiry", "vytvoř tickety z plánu", "rozpadni plán na tickety",
  "/dev:plan-to-jira-tickets".
argument-hint: [Confluence URL or file path]
---

# /dev:plan-to-jira-tickets

Take an implementation plan and produce Stories + Sub-tasks under an existing Jira Epic, with estimates populated. **Never create Epics** — Epics are managed by PMs. $ARGUMENTS

## Prerequisites

### Companion command

This command **delegates per-ticket creation to `/common:create-jira-ticket`**. If that command is not available in the current environment, stop with: `/common:create-jira-ticket command not found; install the common plugin before running /dev:plan-to-jira-tickets`.

Do not re-implement ticket creation logic here — follow the flow defined in `/common:create-jira-ticket` (field resolution, markdown→ADF conversion, MCP call, error handling). This command owns only plan parsing, tree construction, idempotency, batch preview, and orchestration.

### Atlassian MCP

Exposing:

- `mcp__atlassian__getAccessibleAtlassianResources` (read — resolve `cloudId`)
- `mcp__atlassian__createJiraIssue` (write — used via `/common:create-jira-ticket`)
- `mcp__atlassian__editJiraIssue` (write)
- `mcp__atlassian__getConfluencePage` (read)
- `mcp__atlassian__searchJiraIssuesUsingJql` (read, for idempotency check)
- `mcp__atlassian__atlassianUserInfo` (read, for assignee resolution)
- `mcp__atlassian__getTransitionsForJiraIssue` (read, for status transition)
- `mcp__atlassian__transitionJiraIssue` (write, for setting TO-DO status)

If any are missing, stop with a clear error naming the missing tool.

## Inputs

- **Plan source** (required):
  - Confluence page URL or ID (primary) — fetched via `getConfluencePage`, storage format converted to plain structure.
  - Local markdown file path (secondary).
  - If neither provided, ask.
- **Jira context** (required, ask every run):
  - `cloudId` / site URL — resolve via `getAccessibleAtlassianResources` (pick the resource whose `url` matches the site).
  - **parent Epic key** (e.g. `PROJ-42`) — the existing Epic under which all Stories will be created. Never create new Epics. The project key is derived from the Epic key prefix (`PROJ-42` → project `PROJ`).
- **Assignee** — automatically resolved to the current user via `atlassianUserInfo` MCP tool. Do not ask.
- **Optional global fields** (ask once, apply to all tickets):
  - labels, priority. Empty is allowed.

## Mapping Rules

| Source element | Ticket level |
|---|---|
| Plan title (top H1 or Confluence page title) | **Not created** — use as context only. The parent Epic already exists and is provided as input. |
| H1/H2 sections directly under the title | Story (under the provided parent Epic) |
| H3 sections under a Story | Sub-task |
| Bullet item (`- …`) under a Story, **only if it qualifies as an actionable work item** (see "What counts as a Sub-task" below) | Sub-task |
| Bullet item that does **not** qualify (description, acceptance criterion, context, note) | **Not created** — fold into the parent Story's description body |
| Nested bullet (2-space indent under a bullet) | Attach to parent bullet's Sub-task as text; do NOT create a separate Sub-task |
| Checklist item (`- [ ] …`) under a Story, **only if it qualifies as an actionable work item** | Sub-task |

**Never create Epics.** The parent Epic must already exist and is provided as input.

### What counts as a Sub-task

A bullet becomes a Sub-task **only** when it represents real development work — a delivery stage, an isolated feature slice, or a concrete deliverable a developer would pick up and close. Be conservative: when in doubt, fold the bullet into the Story description and surface it in the mapping confirmation so the user can promote it manually.

**Promote to Sub-task when the bullet:**

- Starts with an imperative verb describing engineering work: `Implement`, `Add`, `Migrate`, `Wire up`, `Build`, `Refactor`, `Expose`, `Hook up`, `Persist`, `Backfill`, `Instrument`, `Index`, `Deploy`…
- Names a concrete deliverable or change to the system: a new endpoint, a migration, a job, a screen, a config flip, a contract.
- Maps to a recognizable development stage: schema change, API surface, frontend integration, background job, feature flag rollout, telemetry, docs.

**Keep as description text (do NOT create a Sub-task) when the bullet:**

- Describes a state, fact, or property: `Uses Postgres`, `Runs on the standard runtime`, `Built on top of X`.
- Is an acceptance criterion or behavior assertion: `Returns 200 on success`, `Must support concurrent writes`, `Should not break existing clients`.
- Is context, motivation, or background: `Driven by compliance`, `Follows the pattern from Y`.
- Is a question, an open issue, or a TODO without a clear actor: `What about caching?`, `Decide later`.
- Is a constraint or non-goal: `Out of scope: …`, `Won't change: …`.

**Heuristic when ambiguous:** could a developer realistically open this bullet as a Jira Sub-task, work it to "Done", and have something tangible to show? If yes → Sub-task. If no → description text.

In the mapping confirmation (step 6), explicitly list which bullets were demoted to description text so the user can promote any the heuristic missed.

**Precedence:** If both sub-headings AND bullets appear under a Story, prefer sub-headings as Sub-tasks and render bullets as the Sub-task's description body. If the plan has no H1/H2 sections (flat bullet list under title), demote: each bullet becomes a Story (only if it qualifies as actionable work — non-actionable flat bullets are dropped or surfaced for the user to handle). Flag this in the mapping confirmation so the user can re-map.

## Estimate Detection

**MUST READ** `/common:jira-estimates` for marker syntax (Story Points + hours), placement rules (Story-with-Sub-tasks vs. standalone), and ambiguity handling. The Story Points field ID is instance-specific (e.g. `customfield_XXXXX`); configure your project's actual Story Points field ID, or discover it from the issue field metadata — do not assume another instance's ID.

## Flow

1. **Resolve plan source.** If neither URL nor path provided, ask.
2. **Fetch and parse.** For Confluence: `getConfluencePage` → convert storage format to plain markdown-equivalent structure. For local file: read directly. Extract title, top-level structure, estimate markers.
3. **Resolve Jira context.** Resolve `cloudId` via `getAccessibleAtlassianResources`; prompt for the parent Epic key. Derive the project key from the Epic key prefix (e.g. `PROJ-42` → `PROJ`).
4. **Resolve assignee.** Call `atlassianUserInfo` to get the current user's accountId. All tickets will be assigned to this user.
5. **Propose tree.** Build the Story→Sub-task tree under the provided Epic, with estimates where detected; flag blanks. Remember: Stories with Sub-tasks do NOT get SP — only the Sub-tasks carry SP.
6. **Mapping confirmation.** Show the tree as an outline:

    ```
    Parent Epic: <epic key>
      Story: <title>
        Sub-task: <title> [2 SP, 2h]
        Sub-task: <title> [3 SP, 3h]
      Story: <title> [3 SP]
    ```

    User can: approve (`ok`), re-map a node (`merge Story 2 and 3`, `demote Story 4 to sub-task of Story 3`), or abort.

7. **Idempotency check.** Search Jira for Stories already under the provided Epic (match by summary, case-insensitive, trimmed). If matches found, prompt:
    1. Skip entirely (abort).
    2. Add only Stories/Sub-tasks not already present.
    3. Create all anyway (duplicates possible).
8. **Fill remaining fields.** For each ticket:
    - Description = relevant plan section (Story = section body; Sub-task = bullet + its parent context).
    - Apply assignee (current user), labels/priority from step 3.
    - Story Points via your Jira's Story Points custom field (its ID is instance-specific, e.g. `customfield_XXXXX`; configure your project's actual field ID or discover it from the issue field metadata — do not assume another instance's ID). Apply only on Sub-tasks, or on Stories without Sub-tasks.
9. **Batch preview.** Render a numbered list of every ticket in create order with all resolved fields. Format per ticket: `N. [Type] <new> → <summary>` with compact field lines (SP, OE, parent). Prompt: `create / skip 3,7 / edit 5 / abort`.
10. **Create in order via `/common:create-jira-ticket`.** For each ticket in the approved batch, follow the `/common:create-jira-ticket` flow using the resolved fields from the batch preview. Because the batch preview in step 9 already served as confirmation, invoke `/common:create-jira-ticket` in **batch mode** (skip its per-ticket preview gate — see `/common:create-jira-ticket`'s "Batch Mode" section). All fields needed (cloudId, project, issueType, summary, description, assignee, priority, labels, parent, additionalFields incl. estimate fields) are passed through from the batch.
    - Stories first, each with `parent` = Epic key → capture keys.
    - Sub-tasks next, each with `parent` = Story key.
    - On any failure: stop, report what succeeded, do not attempt rollback.
11. **Post-create: transition to TO-DO.** After each ticket is created, call `getTransitionsForJiraIssue` to find the transition ID for "To Do" status, then call `transitionJiraIssue` to move the ticket to TO-DO. If the transition fails (e.g. already in TO-DO), log a warning and continue.
12. **Summary.** Return: parent Epic key + count (`Created 4 Stories, 11 Sub-tasks under PROJ-42`).

## Safety Gates

Two confirmations are required before any ticket is created:

1. Mapping confirmation (step 6).
2. Batch preview confirmation (step 9).

Never create tickets without BOTH confirmations.

## Dry-Run

If the user says `preview only` or equivalent: run up to step 9 (batch preview), then stop.

## Error Handling

- MCP errors surfaced verbatim, field highlighted.
- On partial-batch failure: print the success list (`Created PROJ-101, PROJ-102; failed on Sub-task 'Deploy staging': <reason>`) and stop. No rollback.
- If estimate field IDs are wrong: the first create will fail with a schema error — report which field is rejected and ask for the correct ID.

## Out of Scope

Epic creation, comments, attachments, sprint/board assignment, automatic custom-field detection beyond Story Points (instance-specific field ID), Original Estimate, and `additionalFields`.
