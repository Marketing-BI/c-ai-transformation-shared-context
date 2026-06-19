---
name: claude-md
description: |
  Scaffold or refresh a project-level CLAUDE.md that captures PROJECT-SPECIFIC facts only — project name and
  purpose, tech stack, architecture/layout, key commands (build/test/run), safe-change rules, decision records,
  and a per-package index for monorepos. Runs in two modes: `init` walks the repo and writes a fresh
  project-overview from scratch; `sync` re-derives the project facts from the current code and refreshes the
  generated sections while preserving every user-written section verbatim. The org's shared engineering
  standards load automatically via the enabled plugins (a SessionStart hook plus the convention skills), so this
  skill never repeats them and never wires shared imports — the project CLAUDE.md stays a thin, project-only
  overview.

  English triggers: "init claude md", "scaffold CLAUDE.md", "generate claude md", "bootstrap CLAUDE.md",
  "create project context", "set up context for this project", "update claude md", "refresh CLAUDE.md",
  "sync CLAUDE.md", "regenerate the project overview", "/dev:claude-md"

  České spouštěče: "vytvoř claude md", "založ CLAUDE.md", "vygeneruj claude md", "nastav kontext projektu",
  "inicializuj projektový kontext", "aktualizuj claude md", "obnov CLAUDE.md", "sesynchronizuj CLAUDE.md",
  "přegeneruj přehled projektu", "/dev:claude-md"

  Do NOT apply when: the user wants a full coding-standards / convention document (those auto-load from the
  plugins — do not duplicate them here), wants freeform notes unrelated to the project overview, or is editing
  an unrelated Markdown file that merely happens to be named CLAUDE.md in another tool's format.
user-invocable: true
argument-hint: '[init | sync] (default: auto-detect — sync if a root CLAUDE.md exists, else init)'
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Project CLAUDE.md — Init / Sync

Maintain a project's `CLAUDE.md` as a **thin project-overview**: the facts about *this* repository that Claude
cannot infer from the shared standards. Two modes:

- **`init`** — no usable `CLAUDE.md` yet. Walk the repo, detect its shape, and scaffold a fresh project-overview
  (plus a per-app `CLAUDE.md` for each deployable app in a monorepo).
- **`sync`** — a `CLAUDE.md` already exists. Re-scan the code, refresh the **generated** project-overview
  sections, and **preserve every user-written section verbatim**. Use after structural changes (a package
  added/removed, a stack shift, a new architectural decision).

Pick the mode from the argument; if none is given, auto-detect: **`sync` when a root `CLAUDE.md` exists, else
`init`**. State which mode you are running before doing anything else.

## What belongs in a project CLAUDE.md (and what does NOT)

**In scope — project-specific only:**

- **Identity** — project name + a one-line purpose.
- **Project Overview** — what the product is, who uses it, what it optimizes for, non-obvious product/UX
  constraints.
- **Tech Stack** — frameworks, language(s), datastore, notable tooling (with versions where they matter).
- **Architecture** — folder layout, responsibilities, data flow, and "where new code goes" rules.
- **Commands** — the real build / test / run / lint commands, quoted verbatim from the repo.
- **Safe-Change Rules** — concrete things Claude must not casually change (public API surface, schema/migrations,
  auth flows, shared contracts, env-var names, generated files).
- **Decisions / ADRs** — short architectural decisions and their rationale, if the project records them.
- **Packages** (monorepos only) — an index of each deployable app's own `CLAUDE.md`.

**Out of scope — never put these here:**

- Coding standards, testing rules, backend/frontend/database/docker conventions, documentation style. **These
  load automatically** from the enabled plugins (a SessionStart hook injects the always-on rules; the
  convention skills add the conditional ones when relevant). Repeating them in the project file is noise that
  drifts out of date.
- Any wiring to shared context — **no `@`-imports of shared files, no shared-rule links, no "applicable /
  not-applicable rule" lists, no per-scope rule selection.** That mechanism does not exist in this setup. The
  project CLAUDE.md is self-contained project facts; the org standards arrive through the plugins.
- README material (Getting Started, Contributing, Deployment runbooks). CLAUDE.md is for decisions Claude makes;
  README is for humans onboarding.

> One sentence is worth including in the generated file so future readers understand the boundary, e.g.:
> *"Org-wide engineering standards load automatically via the enabled plugins — this file only records what is
> specific to this project."*

## Repo analysis (used to POPULATE the overview, language-agnostic)

Detect the repo's shape from **neutral signals** — do not assume any single ecosystem. Look across whatever is
present:

- **Name** — the project manifest's name field (e.g. a package/module/build manifest in the repo's language),
  else the repository directory name.
- **Purpose** — the first heading or lead paragraph of `README.*`; if absent, infer from top-level folders and
  primary dependencies.
- **Tech stack** — read the dependency manifest(s) and lockfile(s) for the repo's language, plus key config
  files (container/build/orchestration/ORM/web-framework config). Identify language(s), framework(s), datastore,
  and notable tooling. Treat every ecosystem the same way — find *a* manifest, don't hardcode one filename.
- **Capabilities present** — note whether the repo has a **backend / service** layer, a **frontend / UI**, a
  **database** (schema, migrations, ORM config), **containerization** (container/compose/orchestration files),
  and a **test suite** (a test runner config or a conventional test directory). These shape the Architecture and
  Safe-Change sections — they are **not** used to pick shared rules.
- **Commands** — the real task definitions: scripts in the manifest, a task-runner file (Make/Just/Taskfile or
  the language's build tool). Quote them verbatim; never invent a command.
- **Monorepo signals** — a workspace/projects declaration in the root manifest, or a monorepo tool's config
  (workspace globs, project graph, task pipeline, multi-package manifest). If present, **enumerate the packages**
  from that config.
  - For each package, record its name, stack signals, and whether it is a **deployable app** (has its own
    container/build/serverless config or its own start/build task) or a **shared library**. Only deployable apps
    get their own `CLAUDE.md`; shared libraries are listed in the root `Architecture` only.

Keep analysis cheap: directory listings plus a few targeted reads of manifests/configs. Do not read source files
exhaustively; one targeted peek is fine when a config is unclear.

---

## Mode: `init`

### 1. Precheck

- If a root `CLAUDE.md` already exists, show it and ask: **overwrite / sync instead / abort**? (Offer
  `per-app only` too when the repo is a monorepo and step 2 finds deployable apps that lack their own
  `CLAUDE.md` — it scaffolds just those missing per-app files and leaves the root and existing per-app files
  untouched.) Do not proceed without an explicit choice. If the user picks "sync", switch to the `sync` mode
  below.

### 2. Scan the repo

Run the **Repo analysis** above. Record: name, purpose, tech stack, capabilities present, commands, and (if a
monorepo) the package list split into deployable apps vs shared libraries.

### 3. Show the plan

In `per-app only` mode, print only the scaffolds for the missing deployable apps (with cited signals) and skip
the root bullets. Otherwise print:

- Detected name + one-line purpose.
- Monorepo: yes / no. If yes, list deployable apps (each gets a per-app `CLAUDE.md`) and shared libraries (root
  `Architecture` only), each with its stack signals.
- Tech stack found — one line of evidence per item (which manifest/config it came from).
- Capabilities present (backend / frontend / database / containerization / tests) with the signal for each.
- Commands that will be quoted verbatim.

Ask: write with this config? (yes / edit / abort). Proceed only on yes.

### 4. Self-check before writing

For every file to be written:

- [ ] Title is the project/app name, not a description.
- [ ] One-line purpose present (a sentence, not a paragraph).
- [ ] **No `@`-imports and no shared-rule links** — the file carries project facts only.
- [ ] Every command is quoted verbatim from a real task definition in the repo; none invented.
- [ ] No section duplicates the shared standards (coding/testing/UI/etc.).
- [ ] Every "Do not introduce" item names a tool actually present in the repo's manifests; no invented
      competitor warnings.
- [ ] Monorepo root: the `Packages` section lists each deployable app with a markdown link to its `CLAUDE.md`
      and a one-line purpose.
- [ ] Per-app files describe decision-shaping constraints (runtime model, concurrency, trust boundaries), not a
      README paraphrase.
- [ ] Long file (>60 lines): every line earns its place by informing Claude's decisions.

Fix any failing check before writing.

### 5. Write files

Substitute placeholders, drop empty sections (don't emit placeholders, don't ask mid-flow — note omissions in
the plan).

#### 5a. Root `CLAUDE.md`

```markdown
# <project-name>

<one-line purpose — what this repo is and what stack it uses>.

> Org-wide engineering standards load automatically via the enabled plugins — this file records only what is
> specific to this project.

## Project Overview

<3–5 sentences: what the product is, who the users are, what it optimizes for, any non-obvious product or UX
constraint. No marketing copy, no origin story.>

## Tech Stack

- <framework + version>
- <language>
- <datastore>
- <notable tooling>

Do not introduce (unless the user explicitly requests):

<OPTIONAL — default is to OMIT. Include a bullet only when it passes one of these tests:

1.  Plausible *addition* test: the alternative could be added alongside the chosen tool as an incremental
    improvement (not a wholesale replacement). Worth a line.
2.  Non-obvious anti-pattern test: the project deliberately contradicts mainstream practice and Claude would
    otherwise default to the mainstream path (e.g. "do not add a separate cache server — we use an in-process
    cache by design").

If the alternative is obviously a full replacement of a stack choice, the Tech Stack list already signals it —
OMIT. When in doubt, OMIT; this section should be rare.>

- <specific tool> — the project uses <chosen tool actually in the manifest>. Include only if a test above passes.

## Architecture

<folder layout + responsibilities + data flow + "where new code goes" rules. 5–15 lines. Describe decision
rules, not just folder names.>

## Packages <!-- monorepo only; omit for single-app -->

Each app has its own `CLAUDE.md`. Claude Code picks up the app's file automatically when you work in that
directory — you do not need to reference it manually.

- [<path/to/app>](<path/to/app>/CLAUDE.md) — <one-line purpose>
- [<path/to/app>](<path/to/app>/CLAUDE.md) — <one-line purpose>

## Commands

- Install: `<cmd>`
- Dev / run: `<cmd>`
- Build: `<cmd>`
- Test: `<cmd>`
- Lint: `<cmd>`
- <type-check / migrate / other real tasks>: `<cmd>`

## Safe-Change Rules

- <concrete rules about what Claude must not casually change: public API routes, DB schema / migrations, auth
  flows, shared contracts, env-var names, generated files. Only items that reflect real constraints in this
  repo.>

## Decisions <!-- optional; include only if the project records architectural decisions -->

- <short decision + one-line rationale, or a link to the ADR location the project keeps.>
```

Rendering rules:

- Single-app repo → omit the `Packages` section entirely.
- A section with no content for this repo → omit it and note the omission in the plan. No placeholders, no
  mid-flow questions.
- **Never** emit `@`-imports or links into shared rule files.

#### 5b. Per-app `CLAUDE.md` (monorepo only)

For each **deployable app**, write `<package-path>/CLAUDE.md`. Shared libraries are covered by the root
`Architecture` only.

```markdown
# <project-name> — <app-name>

<one-line purpose of this app within the monorepo>.

Part of the `<project-name>` monorepo. See the root [CLAUDE.md](<relative-path-to-root>/CLAUDE.md) for the
product overview, tech stack, and architecture.

## App Scope

<1–4 sentences: what this app is, its key stack specifics, and any non-obvious runtime constraint that shapes
decisions (e.g. "stateless — no request-scoped state", "single-threaded event loop, CPU work must be offloaded",
"runs untrusted input in a sandbox"). Decision-shaping, not a README paraphrase.>

## Architecture (local) <!-- only if this app's internal structure is non-trivial and differs from the root overview -->

<folder layout within this app, 3–10 lines.>

## Commands (local) <!-- only if this app's commands differ from the repo root -->

- Dev / run: `<cmd>`
- Build: `<cmd>`
- Test: `<cmd>`
```

Relative-path rules:

- Adjust `<relative-path-to-root>` for the package's nesting depth (one `../` per directory level up to the repo
  root).
- Per-app files carry **no** `@`-imports and **no** shared-rule links either.

### 6. Confirm

After writing, print every file path written, and a one-line next step:
*"Restart your Claude Code session (or reload plugins) to pick up the new CLAUDE.md. After future structural
changes — a new package, a stack shift, a new decision — run `/dev:claude-md sync` to refresh the overview
without re-scaffolding."*

---

## Mode: `sync`

Refresh the **generated** project-overview from the current code while keeping all user-written prose intact.

### 1. Precheck

- Confirm a root `CLAUDE.md` exists. If not, tell the user to run `/dev:claude-md init` and stop.
- Read the root `CLAUDE.md` in full. If a monorepo, enumerate packages and read every existing per-app
  `CLAUDE.md` in full.

### 2. Re-scan the repo (ignore what the file currently claims)

Run the **Repo analysis** afresh — re-derive name, stack, capabilities, commands, and (for monorepos) the
package set with deployable-vs-library detection. The point is to reconcile the file against reality.

### 3. Decide what is generated vs user-owned

Treat as **generated (safe to refresh)** the factual sections this skill produces:

- `## Tech Stack` (the dependency-derived list).
- `## Commands` (the task-derived list).
- `## Packages` (the monorepo index of per-app `CLAUDE.md` links).

Treat as **user-owned (never rewrite)**:

- The title `# <name>` and the one-line purpose under it.
- `## Project Overview`, `## Architecture`, `## Safe-Change Rules`, `## Decisions`, and any section the user
  added (notes, custom ADRs, etc.).
- Per-app `## App Scope`, `## Architecture (local)`, `## Commands (local)` prose.

For user-owned sections, **do not rewrite** — but if a fresh signal contradicts them (the stack changed, a
command disappeared, an app was added/removed), **flag the staleness in the plan** so the user can update it.

> Heuristic: refresh only the mechanical, list-shaped facts (deps, commands, the package index). Anything that
> reads as authored prose stays the user's.

### 4. Compute the diff per file

For each existing file, compare what it claims against the fresh scan and categorize:

- **Tech Stack** — dependencies added / removed / version-bumped → update the list; flag any prose that
  references a now-gone tool.
- **Commands** — tasks added / removed / renamed → update verbatim from the current task definitions.
- **Packages** (monorepo root) — deployable apps whose `CLAUDE.md` exists but is missing from the index → add
  the entry; index entries whose target no longer exists on disk → remove the entry.
- **Structural flags (propose, never execute):** a new deployable app with no `CLAUDE.md` → flag *"run
  `/dev:claude-md init` (per-app) for `<path>`"*; a per-app `CLAUDE.md` for a package that no longer exists →
  flag for the user to remove. This mode **does not create or delete `CLAUDE.md` files**.
- **No shared wiring to reconcile** — there are no `@`-imports or rule links to check; if any stray
  `@`-import of a shared file is found (a leftover from another tooling era), flag it for removal.

### 5. Show the plan

Print a compact diff grouped by file: Tech Stack changes, Commands changes, Packages index changes, staleness
flags on user-owned prose, and structural flags (files for the user to create/remove). List the user-owned
sections being preserved. Ask: apply this diff? (yes / edit / abort). Proceed only on yes.

### 6. Self-check before writing

- [ ] Title and one-line purpose untouched.
- [ ] Every user-owned section preserved **verbatim**, in its original order.
- [ ] Only generated sections (Tech Stack, Commands, Packages index) changed.
- [ ] Every command is verbatim from a real task definition; none invented.
- [ ] `Packages` index matches the deployable per-app `CLAUDE.md` files actually on disk (stale entries removed;
      no new files created here).
- [ ] No file creations or deletions — structural changes are plan-only flags.
- [ ] No `@`-imports or shared-rule links introduced anywhere.

Fix any failing check before writing.

### 7. Write and confirm

Write only existing files, changing **only** the lines inside the generated sections (diff-friendly). Then print
a one-line summary — *"Synced N files. Tech Stack: +A/−B. Commands: refreshed. Packages: +C/−D. User sections
preserved. Flagged for you to handle manually: E."* — and the next step: *"Restart your Claude Code session (or
reload plugins) to pick up the updates."*

---

## Example — backend single-app repo

```markdown
# orders-api

Order ingestion and fulfilment service, deployed as a single containerized backend over a relational datastore.

> Org-wide engineering standards load automatically via the enabled plugins — this file records only what is
> specific to this project.

## Project Overview

Order ingestion and fulfilment service for the e-commerce platform. Consumed by the storefront and admin UI over
HTTP. Optimizes for throughput on order writes and strict consistency on inventory reservations. Single
deployable; no public SDK.

## Tech Stack

- A backend web framework (service layer + HTTP transport)
- A relational datastore accessed through a single ORM / data-access layer
- Containerized local + deploy stack
- A test runner with unit + integration suites

## Architecture

- `<modules-dir>/*` — feature modules (orders, inventory, fulfilment); each owns its transport, service, and
  data-access layers.
- `<shared-dir>/*` — cross-cutting utilities (logging, config, error handling).
- `<migrations-dir>/` — schema + migrations; one migration per logical change.
- New modules follow transport → service → data-access layering. No cross-module imports — go via published
  service APIs.

## Commands

- Install: `<install cmd>`
- Dev / run: `<run cmd>`
- Build: `<build cmd>`
- Test: `<test cmd>`
- Lint: `<lint cmd>`
- DB migrate: `<migrate cmd>`

## Safe-Change Rules

- Do not rename public routes under `/v1/*` without bumping to `/v2/*` — consumers are pinned.
- Do not edit generated migration files; always create a new migration.
- Flag any change to the env-var schema explicitly; it affects deployment.
```

## Anti-patterns

- **Do not wire shared context.** No `@`-imports of shared files, no rule links, no applicable/not-applicable
  lists, no per-scope rule selection. The org standards load via the plugins; the project file is project facts
  only.
- **Do not duplicate the shared standards.** Coding / testing / convention content lives in the plugins, not
  here.
- **Do not invent commands.** Quote only real task definitions from the repo.
- **Do not invent "Do not introduce" warnings.** Each must name a tool actually present in the manifests, and
  must pass the addition or anti-pattern test — otherwise omit.
- **Do not emit placeholders** ("TODO: add overview"). Omit empty sections and note the omission in the plan;
  never ask mid-flow.
- **`sync` does not rewrite authored prose.** Refresh only the mechanical facts (Tech Stack, Commands, Packages
  index). Flag stale prose; let the user edit it.
- **`sync` does not create or delete files.** New deployable apps and stale per-app files are plan-only flags for
  the user.
- **Do not add README material** (Getting Started, Contributing, Deployment). CLAUDE.md is for decisions Claude
  makes.
