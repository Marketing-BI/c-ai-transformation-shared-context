---
description: |
  Create Stories + Sub-tasks under an existing Jira Epic from an implementation plan (a Confluence page or a local
  markdown file). Never creates Epics. Use for: "plan to jira", "create tickets from plan",
  "break the plan into tickets", "plán do jiry", "vytvoř tickety z plánu", "rozpadni plán na tickety",
  "/dev:plan-to-jira-tickets".
argument-hint: [Confluence URL or file path]
---

# /dev:plan-to-jira-tickets

Take an implementation plan and produce Stories + Sub-tasks under an existing Jira Epic. **Never create Epics** — Epics are managed by PMs. Estimates from the plan are surfaced in the preview for manual entry — the Hub connector can't write custom estimate fields. $ARGUMENTS

## Prerequisites

### Companion command

This command **delegates per-ticket creation to `/common:create-jira-ticket`**. If that command is not available in the current environment, stop with: `/common:create-jira-ticket command not found; install the common plugin before running /dev:plan-to-jira-tickets`.

Do not re-implement ticket creation logic here — follow the flow defined in `/common:create-jira-ticket` (field resolution, MCP call, error handling). This command owns only plan parsing, tree construction, idempotency, batch preview, and orchestration.

### Atlassian MCP

Exposing:

- `atlassian_list_sites` (read — list Atlassian sites)
- `atlassian_set_active_site` (write — switch site, only if multi-site)
- `jira_create_issue` (write — used via `/common:create-jira-ticket`)
- `confluence_get_page` (read)
- `jira_search` (read, for idempotency check)
- `atlassian_user_info` (read, for assignee resolution)
- `jira_get_transitions` (read, for status transition)
- `jira_transition_issue` (write, for setting TO-DO status)

If any are missing, stop with a clear error naming the missing tool.

## Inputs

- **Plan source** (required):
  - Confluence page URL or ID (primary) — fetched via `confluence_get_page` (returns the body as Markdown).
  - Local markdown file path (secondary).
  - If neither provided, ask.
- **Jira context** (required, ask every run):
  - **Atlassian site** — the Hub uses the connection's active site; you don't pass a `cloudId`. If your team works across multiple sites, switch once with `atlassian_set_active_site` before creating.
  - **parent Epic key** (e.g. `PROJ-42`) — the existing Epic under which all Stories will be created. Never create new Epics. The project key is derived from the Epic key prefix (`PROJ-42` → project `PROJ`).
- **Assignee** — automatically resolved to the current user via `atlassian_user_info`. Do not ask.
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

Read each task's effort estimate directly from the plan (the plan skill records a numeric estimate per task) and **surface it in the mapping outline and batch preview** so it's easy to transcribe. The Hub connector **cannot write custom estimate fields** (or any custom field), so estimates are **not** set on the created tickets — the user adds them manually in Jira afterward. For a Story with Sub-tasks, show the estimate on whichever level your team tracks; if the plan's estimate placement is ambiguous, ask the user.

## Flow

1. **Resolve plan source.** If neither URL nor path provided, ask.
2. **Fetch and parse.** For Confluence: `confluence_get_page` (returns Markdown). For local file: read directly. Extract title, top-level structure, estimate markers.
3. **Resolve Jira context.** Ensure the correct Atlassian site is active (only if your team uses multiple sites; switch via `atlassian_set_active_site`); prompt for the parent Epic key. Derive the project key from the Epic key prefix (e.g. `PROJ-42` → `PROJ`).
4. **Resolve assignee.** Call `atlassian_user_info` to get the current user's accountId. All tickets will be assigned to this user.
5. **Propose tree.** Build the Story→Sub-task tree under the provided Epic, showing estimates where detected (for manual entry — see Estimate Detection); flag blanks. Convention: show the estimate on Sub-tasks, or on Stories without Sub-tasks.
6. **Mapping confirmation.** Show the tree as an outline:

    ```
    Parent Epic: <epic key>
      Story: <title>
        Sub-task: <title> [2h]
        Sub-task: <title> [3h]
      Story: <title> [3h]
    ```

    User can: approve (`ok`), re-map a node (`merge Story 2 and 3`, `demote Story 4 to sub-task of Story 3`), or abort.

7. **Idempotency check.** Search Jira for Stories already under the provided Epic (match by summary, case-insensitive, trimmed). If matches found, prompt:
    1. Skip entirely (abort).
    2. Add only Stories/Sub-tasks not already present.
    3. Create all anyway (duplicates possible).
8. **Fill remaining fields.** For each ticket:
    - Description = relevant plan section (Story = section body; Sub-task = bullet + its parent context), as Markdown (the connector converts it to ADF).
    - Apply assignee (current user), labels/priority from step 3.
    - Effort estimates are **not** written — the Hub connector can't set custom fields. They're shown in the preview for the user to enter manually in Jira.
9. **Batch preview.** Render a numbered list of every ticket in create order with all resolved fields. Format per ticket: `N. [Type] <new> → <summary>` with compact field lines (estimate, parent). Prompt: `create / skip 3,7 / edit 5 / abort`.
10. **Create in order via `/common:create-jira-ticket`.** For each ticket in the approved batch, follow the `/common:create-jira-ticket` flow using the resolved fields from the batch preview. Because the batch preview in step 9 already served as confirmation, invoke `/common:create-jira-ticket` in **batch mode** (skip its per-ticket preview gate — see `/common:create-jira-ticket`'s "Batch Mode" section). All fields needed (project, issueType, summary, description, assignee, priority, labels, parent) are passed through from the batch.
    - Stories first, each with `parent` = Epic key → capture keys.
    - Sub-tasks next, each with `parent` = Story key.
    - On any failure: stop, report what succeeded, do not attempt rollback.
11. **Post-create: transition to TO-DO.** After each ticket is created, call `jira_get_transitions` to find the transition ID for "To Do" status, then call `jira_transition_issue` to move the ticket to TO-DO. If the transition fails (e.g. already in TO-DO), log a warning and continue.
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

## Out of Scope

Epic creation, comments, attachments, sprint/board assignment, and any custom fields — including effort estimates. The Hub connector can't write custom fields; estimates are surfaced in the preview for manual entry only.
