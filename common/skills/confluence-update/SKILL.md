---
name: confluence-update
description:
  Use whenever the user wants to create or update a Confluence page. Triggers on phrases like "write to
  Confluence", "create a Confluence page", "update the Confluence page", "publish to Confluence", "document this
  in Confluence", "napiš do Confluence", "vytvoř stránku v Confluence", "aktualizuj Confluence stránku",
  "publikuj do Confluence", "zdokumentuj to v Confluence", or "/common:confluence-update". Enforces
  durable-knowledge standards — only publish decisions, runbooks, architecture docs, and project context; never
  publish WIP notes, meeting notes without decisions, or content that belongs in code. This is the canonical way
  to write to Confluence so that pages are consistent, non-duplicated, and safe to publish.
---

# Confluence Update

Create or update a Confluence page with durable, team-visible knowledge. The goal is to publish content that will
remain useful over time — not every piece of information belongs in Confluence, and publishing the wrong things
creates noise that erodes trust in the space.

## When to use

Trigger on any of:

- "write this to Confluence"
- "create a Confluence page for [topic]"
- "update the Confluence page on [topic]"
- "publish [document] to Confluence"
- "document this decision in Confluence"
- "napiš to do Confluence"
- "vytvoř Confluence stránku pro [téma]"
- "aktualizuj Confluence stránku o [tématu]"
- "zdokumentuj toto rozhodnutí v Confluence"

## What belongs in Confluence

Write to Confluence when documenting:

- An architectural or technical decision
- A runbook, setup guide, or operational procedure
- Project scope, team contacts, or key context
- A post-mortem or retrospective output

Do **not** write to Confluence for:

- Work-in-progress notes — use local files first, review, then publish
- Information that belongs in code comments or README
- Meeting notes without decisions — only decisions go in; raw notes do not
- Content that will be superseded within days

## How to run

### Step 1 — Draft locally first

Write the content as a local `.md` file and review it before publishing. Never publish a first draft directly.

### Step 2 — Pre-publish checks

Before creating or updating:

1. Search Confluence to confirm no duplicate page exists
2. Confirm the target space and parent page with the user
3. Verify the content contains no sensitive data: credentials, PII, internal financials

### Step 3 — Page structure

Every page must have:

- A clear, descriptive title — include component and scope (e.g. `Auth Service: Token Rotation Runbook`, not just
  `Runbook`)
- A one-line summary at the top: what the page is and who it is for
- A `Last updated` date

### Step 4 — Creating vs. updating

**Creating a new page:**

- Confirm the target space and parent page before calling the MCP tool
- Use `mcp__atlassian__createConfluencePage`

**Updating an existing page:**

- Preserve the existing structure unless restructuring is the explicit goal
- Append to sections rather than overwriting, unless making corrections
- Never remove content without confirming it is no longer needed
- Update the `Last updated` date after any meaningful change
- Use `mcp__atlassian__updateConfluencePage`

## Edge cases and failure modes

- **Duplicate page found** — surface the existing page to the user and ask whether to update it or create a new
  one; never silently create a duplicate.
- **Target space or parent ambiguous** — ask before creating; do not guess the location.
- **Sensitive content detected** — stop and flag it; do not publish credentials, PII, or internal financials under
  any circumstances.
- **Page too large** — if the content is very long, suggest splitting into sub-pages rather than creating a single
  unwieldy page.

## Why this skill exists

Confluence pages created ad-hoc tend to be duplicated, poorly structured, or published in the wrong space. This
skill exists to enforce a consistent quality bar — local draft first, duplicate check, structure requirements —
so that every published page is immediately useful and easy to find.
