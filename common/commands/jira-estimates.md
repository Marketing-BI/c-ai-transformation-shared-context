---
description: Jira estimate-marker syntax, placement rules, and ambiguity handling — shared reference for plan-based ticket creation. Use for: "estimate tickets", "story points", "add estimates", "odhadni úkoly", "přidej odhad", "/common:jira-estimates".
---

# Command: jira-estimates

Shared rules for detecting and writing Jira estimates (Story Points + Original Estimate / hours) when creating tickets from a plan. Referenced by `/common:create-jira-ticket` and any plan-to-tickets batch workflow.

Estimates can appear on **any ticket level** (Story, Sub-task). Both Story Points and hours can coexist on the same item — both fields will be populated when present.

## Story Points field

Story Points are **always** written to `customfield_10033`. Do not ask the user for the field ID.

## Story Points markers (case-insensitive)

- `[SP: 5]`
- `[5 SP]` / `[5sp]`
- `(8 SP)` / `(8 story points)`
- `story points: 5`
- `SP=5`

## Hours markers (Original Estimate)

- `[2h]` / `[2 h]`
- `~3h`
- `(4 hours)` / `(4h)`
- `estimate: 3h`
- `est: 3h`

Decimals allowed: `[1.5h]`, `(2.5 hours)`.

## Placement rules

- **Story with Sub-tasks:** Do NOT set Story Points on the parent Story. Only Sub-tasks carry SP. The Story's SP is the sum of its Sub-tasks (Jira handles this automatically).
- **Story without Sub-tasks:** Story Points go on the Story itself.
- **Sub-task:** Story Points go on the Sub-task.
- Missing marker → leave that field blank. Never guess, never infer, never apply a default.
- Original Estimate is written in **hours** (e.g. `"2h"`, `"1.5h"`). Do not convert to seconds — pass the hour value to the MCP tool as-is, typically as `timetracking: { originalEstimate: "2h" }` (or as a customfield string value if the project uses one). `30 minutes` is NOT recognized — round up to the nearest hour or leave blank, don't guess fractional conversions.

## Ambiguity

If a single line contains the same kind of marker twice (e.g. `[5 SP]` and `(8 SP)`), use the first occurrence and flag the ambiguity in the mapping confirmation. A line containing one SP marker and one hours marker is fine — both apply.
