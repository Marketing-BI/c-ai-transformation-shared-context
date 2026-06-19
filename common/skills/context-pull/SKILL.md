---
name: context-pull
description: >
  Use whenever the user needs a consolidated picture of a project before a meeting, gate check, implementation start,
  handover, or activity digest. Triggers on phrases like: "pull context for", "get context on", "give me context before",
  "what's the status of", "catch me up on", "context for <project>", "načti kontext pro", "shrň stav projektu",
  "co se děje v projektu", "přehled projektu před schůzkou", "dej mi kontext k", "/common:context-pull".
  Invokes the context-pull agent to retrieve relevant context from Jira and Confluence in parallel and
  returns a structured summary. This is the canonical way to load cross-system context for a project before any
  workflow that depends on knowing the current state.
---

# Context Pull

Retrieve a consolidated picture of a project so you (and the user) have full context before a meeting,
implementation, gate check, handover, or digest. Pulling everything up-front — Jira, Confluence — prevents
the back-and-forth of "wait, what was decided?" or "did anyone follow up on that?"

**This skill produces high-quality output when given focused inputs.** The best time to run it is before a
specific meeting or task, with a focused topic and (optionally) an epic ID so Jira retrieval is scoped
to the right work.

## When to use

Trigger on any of:

- "pull context for [project]"
- "get context on [project/topic]"
- "give me context before [meeting/task]"
- "catch me up on [project]"
- "what's the status of [project]"
- "context for [project]"
- "načti kontext pro [projekt]"
- "shrň stav projektu [projekt]"
- "co se děje v projektu [projekt]"
- "přehled projektu před schůzkou"
- "dej mi kontext k [projekt/téma]"
- Any request for a cross-system project overview before starting work

**Ideal triggers** — before a meeting or at implementation start: "pull context for the auth migration before I start implementing", "catch me up on PROJ before the planning session".

## Inputs

### Step 1 — Resolve project routing parameters

Look up the project's routing configuration from the consuming project's defined source (e.g. a routing index, project
README, or overview file). You need:

| Parameter | Description |
|---|---|
| `jira_prefix` | Jira project key (e.g. `PROJ`) |
| `confluence_space` | Confluence space key |

If the routing parameters are not defined, stop and ask the user to provide them or point to where they are documented.

### Step 2 — Collect remaining inputs

If not already provided by the user, ask for:

| Parameter | Required | Notes |
|---|---|---|
| `project` | Yes | Project name or identifier |
| `topic` | Yes | Specific topic or feature to focus on — the narrower the better (e.g. `auth token rotation`, not `auth`) |
| `use_case` | Yes | One of: `meeting-context`, `brief`, `activity`, `gate-check`, `handover` |
| `date_from` | No | Lookback window (default: 14 days ago) — narrow this when the topic is recent |
| `epic_id` | No | Jira epic to scope retrieval — strongly recommended; omitting it broadens results significantly |
| `output_file` | No | Path to write consolidated context as a `.md` file |

## How to run

### Step 3 — Invoke the context-pull agent

Call the `context-pull` agent via the Agent tool with `subagent_type: "common:context-pull"` and all resolved
parameters. The agent runs all source retrievals in parallel and returns a consolidated summary.

### Step 4 — Return the output

Present the consolidated context summary to the user. If `output_file` was specified, write the output to that path as
a `.md` file.

## Edge cases and failure modes

- **Routing parameters missing** — stop and ask the user to provide them; do not guess project keys or space slugs.
- **Source system unavailable** — report which system failed and present partial results from the others rather than
  failing entirely.
- **No results from a source** — include an explicit "No results" note per source so the user knows it was queried, not
  skipped.
- **Topic too broad or no epic filter** — if `topic` is generic (single word, project name only) or no `epic_id` is
  provided, pause before invoking the agent and ask the user to narrow the scope. A broad pull returns low-signal noise
  and may surface outdated or ambiguous information. Suggest: a specific feature name, an epic ID, or a tighter date window.

## Why this skill exists

Context for ongoing work lives across multiple systems — a Jira epic, a Confluence spec. Retrieving these one-by-one
mid-conversation is slow and breaks flow. This skill exists to pull everything in one parallel pass so the user can
start the actual work immediately.
