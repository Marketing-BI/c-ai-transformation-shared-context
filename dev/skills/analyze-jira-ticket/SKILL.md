---
name: analyze-jira-ticket
description: |
  Use when the user wants to analyse a Jira ticket against the current codebase and get observational context
  (no plan, no questions). Loads the ticket (via /common:read-jira-ticket), detects the repository's structure
  (including monorepo layout) with language-agnostic signals, scans the relevant packages for code touching the
  ticket's domain, and produces a **structured context dump** (detected structure, target packages, ticket
  requirements, related code, observations, backward-compatibility notes). This skill is **load + code scan only**
  — it does NOT ask clarifying questions, does NOT propose a plan, and does NOT hand off to implement. Planning is
  owned by `/dev:plan` or by the user (writing a plan from this output).

  English triggers: "analyze ticket", "analyse this ticket", "analyze PROJ-123", "what does PROJ-123 touch in the
  code", "scan the code for FEAT-456", "gather context for OPS-789", "/dev:analyze-jira-ticket"

  České spouštěče: "analyzuj ticket", "analyzuj tiket", "analyzuj PROJ-123", "čeho se PROJ-123 dotýká v kódu",
  "projdi kód k FEAT-456", "seber kontext k OPS-789", "rozbor tiketu", "/dev:analyze-jira-ticket"

  Do NOT apply when: the user already has an approved plan and wants to start implementing (use
  /dev:implement-from-analysis), only wants to read the ticket content with no codebase analysis (use
  /common:read-jira-ticket), or wants a formal implementation plan (use /dev:plan).
---

# Analyze Jira Ticket — load + code scan + structured context

Take a Jira ticket and produce a structured context dump: what the ticket says + which code is involved + what
observations the codebase yields about implementing it.

This skill is **observational only**. It does not propose an implementation plan, does not ask the user
clarifying questions, and does not hand off to any downstream skill. Its output is context for someone (the user,
or `/dev:plan`, or `/dev:develop`) to make planning decisions from.

## When NOT to use

- The user wants to start implementing immediately with an approved plan → use `/dev:implement-from-analysis`.
- The user wants to see only the ticket content (no codebase analysis) → use `/common:read-jira-ticket`.
- The user wants a formal implementation plan with reviews / estimates → use `/dev:plan`.

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
transcripts of video attachments, transcribed via an available ASR — handled by read-jira-ticket), linked tickets,
and referenced documentation pages. Do **not** re-implement ticket fetching — always delegate.

If the read skill fails (missing integration, permission denied, ticket not found), stop and surface the error. Do
not invent ticket content.

### 2. Detect repository structure

Before scanning code, understand the layout. Stay language-agnostic — detect by neutral, cross-stack signals, not by
assuming any one ecosystem. Detect in this order:

1. **Workspace / monorepo manifests at root** — any tool that declares multiple sub-projects, e.g. a workspace
   manifest, a multi-module build descriptor, or a monorepo task-runner config. The shape varies by stack (a
   workspace file, a multi-module build file, a solution file, a task-graph config); treat any root file that
   enumerates sub-projects or a task graph across them as a monorepo signal.
2. **Typical monorepo folders**: `apps/`, `packages/`, `services/`, `libs/`, `modules/`, `backend/`, `frontend/`,
   `server/`, `client/`.
3. **All project/build manifests below root** — locate each sub-project by its own manifest/build file (the
   per-language descriptor that marks a buildable unit). Exclude vendored/build output dirs (dependency caches,
   compiled output, generated artifacts).
4. **Classify each package by role** — describe its *role*, not its framework:
   - **Server / service**: has a server entry point, HTTP route/controller definitions, or an application bootstrap.
   - **Client / UI**: has a client/app entry point, view/component files, a bundler or app-framework config.
   - **Data / persistence**: holds schema definitions, migrations, or a data-access layer.
   - **Shared library / types / utils**: no server or client entry point — exports reusable code only.

Output the detected structure explicitly at the start of the analysis, naming the *role* of each unit (and its stack
only as observed, not assumed):

```
Detected structure: monorepo, multiple sub-projects
  <path-to-server>/     server / service       (primary target)
  <path-to-client>/     client / UI            (secondary target)
  <path-to-shared>/     shared library / types
```

If the repo is a single-package project, say so — the analysis then treats the whole repo as one target.

### 3. Identify relevant packages for this ticket

Map ticket keywords (domain terms, feature names, API paths, data entities, error messages) against the detected
packages. Flag:

- **Primary target(s)** — packages that clearly own the change.
- **Likely secondary** — packages that may need coordinated changes (e.g. a shared library for a shared-type rename).
- **Out of scope** — packages unlikely to be touched.

If ambiguous, **note the ambiguity in the output** — do not ask the user (this skill is observational).

### 4. Scope the code scan

In each primary and likely-secondary package, search for:

- Files matching ticket keywords (route handlers, controllers, services, schemas, views/components, models)
- Existing patterns the change would extend or touch
- External services / integrations referenced in the ticket (any third-party service or API) — find their current
  abstraction layer in this codebase
- Error messages or log patterns (for bug tickets)

Use `Grep` / `Glob` / `Read` purposefully. Do not read the whole codebase — only files plausibly related to the
ticket. **Hard cap: do not read more than ~20 files.** If you are about to exceed that, stop scanning and note in
the output that the scan was capped (so the consumer knows the coverage might be incomplete).

### 5. Apply project rules (observational)

The always-rules (coding standard, practices, documentation, monorepo) and the conditional convention skills
selected for this project (backend, database, etc.) have already auto-loaded via the enabled plugin. **Use them as
a checklist** when observing the code.

Note any obvious rule violations a naive implementation would introduce (e.g. weakening type/contract safety,
breaking layer boundaries, scattering hardcoded constants) — as observations in the output, not as recommendations.

### 6. Produce the structured context dump

Use this exact structure (do not omit sections, use "none found" where applicable). **Output is observational —
no proposed actions, no questions for the user, no plan.**

```
## Ticket Analysis: <TICKET-KEY>

### Ticket content (from /common:read-jira-ticket)
<summary line + key facts: title, status, type, description summary, key comments/decisions
referenced, linked tickets/pages>

### Detected structure
<one-line: single-package, monorepo + sub-projects, etc.>

### Target packages
- <package>: <why this package is in scope> (primary | likely secondary | out of scope)
- <ambiguity notes if applicable>

### What the ticket asks for (extracted)
- <bullet per requirement, drawn from description / AC / comments, no speculation>

### Related code found
- `<path>` — <one-line: what it does, why it's related>
- ...

### Code observations
- existing pattern X in `<path>` that a change here would extend
- external service / integration Y currently wrapped in `<abstraction>`
- naive implementation would violate rule R (e.g. weaken contract safety at boundary B)
- ...

### Backward-compatibility notes
- API breaking risk: <e.g. existing endpoint signature, public contract field>
- Data migration risk: <e.g. column rename, type narrowing>
- "No backward compatibility concerns observed" if none.

### Scan coverage
- Files read: <count> / 20-cap
- Packages scanned: <list>
- Note if scan was capped or significantly narrowed.
```

That's the full output. Skill stops here. **Do not** ask "want a plan?", **do not** propose a task list, **do
not** invoke any downstream skill.

## Anti-patterns

- **Do not implement anything.** This skill is observational only.
- **Do not propose a plan.** No ordered task list, no "what's missing — needs to be built" prescriptions. State
  what's there and what's not as observations; planning is a separate concern (owned by `/dev:plan` or the user).
- **Do not ask the user clarifying questions.** Ambiguities go into the output as notes, not as questions. The
  consumer of this output (user / `/dev:plan` / `/dev:develop`) decides whether/how to resolve them.
- **Do not re-implement ticket fetching.** Always delegate to `/common:read-jira-ticket`.
- **Do not hallucinate requirements.** Every extracted requirement must be traceable to the ticket (description,
  AC, comment). If the ticket is ambiguous, note the ambiguity — don't fill gaps from imagination.
- **Do not scan the whole repo.** Hard cap ~20 files. If you'd exceed it, stop and note the cap in the output.
- **Do not hand off to downstream skills.** No "Ready for implement-from-analysis" prompt at the end. The output
  is the deliverable; what happens next is up to the consumer.
