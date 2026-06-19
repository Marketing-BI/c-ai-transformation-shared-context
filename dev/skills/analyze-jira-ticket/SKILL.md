---
name: analyze-jira-ticket
description: |
  Use when the user wants to analyse a Jira ticket against the current codebase before implementation. Loads the
  ticket (via /common:read-jira-ticket), detects the repository's structure (including monorepo layout) with
  language-agnostic signals, scans the relevant packages for code touching the ticket's domain, and produces a
  structured analysis with requirements, existing code, gaps, risks, and open questions. Then asks the user
  clarifying questions and confirms a plan before handing off to /dev:implement-from-analysis. This skill is
  **analysis only** — it never implements code.

  English triggers: "analyze ticket", "analyse this ticket", "analyze PROJ-123", "what needs to change for
  FEAT-456", "prepare implementation plan for OPS-789", "scope this ticket", "/dev:analyze-jira-ticket"

  České spouštěče: "analyzuj ticket", "analyzuj tiket", "analyzuj PROJ-123", "co je potřeba změnit pro FEAT-456",
  "připrav implementační plán pro OPS-789", "naceň tiket", "rozbor tiketu", "/dev:analyze-jira-ticket"

  Do NOT apply when: the user already has an approved plan and wants to start implementing (use
  /dev:implement-from-analysis), or only wants to read the ticket content with no codebase analysis (use
  /common:read-jira-ticket).
---

# Analyze Jira Ticket

Prepare a Jira ticket for implementation: load the ticket, understand what's required, scan the codebase to see
what exists, identify gaps and risks, and produce a plan the user can approve.

This skill is **analysis only**. It never writes production code. The output is a plan plus open questions — ready
for `/dev:implement-from-analysis` to take over.

## When NOT to use

- The user wants to start implementing immediately with an approved plan → use `/dev:implement-from-analysis`.
- The user wants to see only the ticket content (no codebase analysis) → use `/common:read-jira-ticket`.

## Ticket key resolution

Mandatory — the skill needs a ticket key to proceed. Resolve in this order:

1. **Explicit argument**: `/dev:analyze-jira-ticket PROJ-123`
2. **Inline in message**: "analyze PROJ-123", "what about FEAT-456", any `[A-Z][A-Z0-9_]+-\d+` pattern
3. **Git branch fallback**: `git branch --show-current` → extract the ticket pattern from names like
   `feat/PROJ-123-description`, `fix/FEAT-456-bug`
4. **Ask** — if no key anywhere, ask the user. Do not guess.

When resolved from the git branch, state it explicitly:
> "No ticket key in the prompt — using `PROJ-123` from the current branch. Continuing unless you say otherwise."

## Procedure

### 1. Load the ticket

Invoke `/common:read-jira-ticket` with the resolved key. This pulls description, comments, attachments (including
transcripts of video attachments where available), linked tickets, and referenced documentation pages. Do **not**
re-implement ticket fetching — always delegate.

If the read skill fails (missing integration, permission denied, ticket not found), stop and surface the error. Do
not invent ticket content.

### 2. Detect repository structure

Before scanning code, understand the layout. Stay language-agnostic — detect by neutral, cross-stack signals, not by
assuming any one ecosystem. Detect in this order:

1. **Workspace / monorepo manifests at root** — any tool that declares multiple sub-projects, e.g. a workspace file,
   a multi-module build descriptor, or a monorepo task-runner config. Common shapes across stacks:
   - JS/TS: a workspace file or `workspaces` field, an Nx/Turbo/Lerna config
   - JVM: a multi-module build file (Gradle/Maven aggregator)
   - .NET: a solution file aggregating multiple projects
   - Other: any root file that enumerates sub-projects or a task graph across them
2. **Typical monorepo folders**: `apps/`, `packages/`, `services/`, `libs/`, `modules/`, `backend/`, `frontend/`,
   `server/`, `client/`.
3. **All project/build manifests below root** — locate each sub-project by its own manifest/build file (the
   per-language descriptor that marks a buildable unit). Exclude vendored/build output dirs (dependency caches,
   compiled output, generated artifacts).
4. **Classify each package** by neutral signals — describe its *role*, not its framework:
   - **Backend / service**: has a server entry point, HTTP route/controller definitions, or an application bootstrap.
   - **Frontend / UI**: has a client/app entry point, view/component files, a bundler or app-framework config.
   - **Data / persistence**: holds schema definitions, migrations, or a data-access layer.
   - **Shared library / types / utils**: no server or client entry point — exports reusable code only.

Output the detected structure explicitly at the start of the analysis, naming the *role* of each unit (and its stack
only as observed, not assumed):

```
Detected structure: monorepo, multiple sub-projects
  <path-to-backend>/    backend service        (primary target)
  <path-to-frontend>/   frontend / UI          (secondary target)
  <path-to-shared>/     shared types / schemas
```

If the repo is a single-package project, say so — the analysis then treats the whole repo as one target.

### 3. Identify relevant packages for this ticket

Map ticket keywords (domain terms, feature names, API paths, data entities, error messages) against the detected
packages. Flag:

- **Primary target(s)** — packages that clearly own the change.
- **Likely secondary** — packages that may need coordinated changes (e.g. a shared package for a shared-type rename).
- **Out of scope** — packages unlikely to be touched.

If ambiguous, ask the user before continuing.

### 4. Scope the code scan

In each primary and likely-secondary package, search for:

- Files matching ticket keywords (route handlers, controllers, services, schemas, views/components, models)
- Existing patterns the change would extend or touch
- External integrations referenced in the ticket (any third-party service or API) — find their current abstraction
  layer in this codebase
- Error messages or log patterns (for bug tickets)

Use `Grep` / `Glob` / `Read` purposefully. Do not read the whole codebase — only files plausibly related to the
ticket. Hard cap: do not read more than ~20 files. If you are about to exceed that, pause and ask the user to
narrow the scope.

### 5. Apply project rules

The applicable convention/standard skills for this repo (coding standard, practices, documentation, and the
conditional ones for this project — backend, database, etc.) define what "good" looks like here. **Use them as a
checklist** when analysing the proposed change.

Flag any obvious rule violations the ticket's naive implementation would introduce (e.g. breaking layer boundaries,
scattering hardcoded constants, weakening type/contract safety, leaking internal errors).

### 6. Produce the structured analysis

Use this exact structure (do not omit sections; use "none found" where applicable):

```
## Ticket Analysis: <TICKET-KEY>

### Detected structure
<one-line: single-package, monorepo + sub-projects, etc.>

### Target packages
- <package>: <why this package is in scope>

### What the ticket requires
- <bullet per requirement, drawn from description / AC / comments, no speculation>

### What already exists in code
- `<path>` — <one-line: what it does, how it's relevant>
- ...

### What's missing / needs to be built
- <bullet per new component, endpoint, schema, screen, model, etc.>

### Risks and considerations
- Technical risks, integration points, concurrency, scale
- Rule violations the naive approach would introduce

### Backward compatibility
- API breaking changes, data migrations, dependent systems
- "No backward compatibility concerns" if none found

### Open questions for the user
- <specific question that blocks planning — e.g. "Should retries be idempotent at the endpoint or the webhook level?">
```

### 7. Interactive Q&A

Show the analysis. For each open question, ask explicitly. Wait for the user's answers before proposing a plan —
do not guess defaults for blocking decisions.

### 8. Propose the plan

Once open questions are answered, propose an ordered task list:

```
## Proposed plan

1. <task> — package: <pkg>, affects: <files/areas>
2. <task> — ...
3. <task> — ...

Reviewers to dispatch after implementation: <e.g. backend-architect, security-reviewer — based on scope>
Tests: <unit / integration / e2e, per task>
```

Ask: *"Approve this plan? (yes / edit / abort)"*

### 9. Handoff

On approval, state clearly:
> "Plan approved. Ready for `/dev:implement-from-analysis`. Paste or reference this analysis when invoking it."

Do **not** start implementing. Stop here. The user will invoke the implement skill when ready (often in a separate
session to keep the token budget clean).

## Anti-patterns

- **Do not implement anything.** This skill is analysis-only.
- **Do not re-implement ticket fetching.** Always delegate to `/common:read-jira-ticket`.
- **Do not hallucinate requirements.** Every requirement must be traceable to the ticket (description, AC, comment).
  If the ticket is ambiguous, ask — do not fill gaps from imagination.
- **Do not skip Q&A.** Open questions must be answered by the user before planning.
- **Do not scan the whole repo.** Scope to packages relevant to the ticket; cap file reads; if you need more, ask.
- **Do not assume a stack.** Detect structure by role-based signals; do not hardcode one language's conventions.
- **Do not combine analysis and implementation in one output.** Stop at "Plan approved."
