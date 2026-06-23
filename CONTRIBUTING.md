# Contributing to Shared AI Context

This guide describes how to extend this repository — adding or editing rules, commands, skills, agents, or plugin manifests. The repo is a Claude Code plugin marketplace consumed **as plugins** (no git submodule); changes ship to consumers automatically once merged and the marketplace is refreshed.

## Where things live

The repository is three plugins, each a top-level directory with its own `.claude-plugin/plugin.json`:

- **`common/`** — shared across all teams. Changes here affect everyone, so review impact carefully.
- **`dev/`** — engineering teams. Software-delivery conventions, workflow, planning, and reviewer agents.
- **`business/`** — commercial teams. CRM discipline, SOW/Brief generators, prospecting, and sales-call coaching.

The marketplace itself is declared in `.claude-plugin/marketplace.json`, which lists each plugin and its `source` directory.

## Naming and cross-references

- **Bare own names.** A skill, command, or agent's own `name:` (and, for skills, its directory) is **bare** — `git-commit`, `read-jira-ticket`, `sow`. There is no plugin prefix on a component's own name. For skills, the directory name **must equal** the frontmatter `name:`.
- **Plugin-qualified cross-references.** Whenever you reference another component, qualify it with its plugin: commands and skills as `/common:read-jira-ticket` or `/dev:open-pr`; agent dispatch as `subagent_type: "dev:backend-architect"`. Never write a bare cross-reference.

## Adding rules

Rules come in two kinds:

- **Always-on rules** live directly in `<plugin>/rules/*.md` (flat — no sub-folders). They are assembled and injected into **every** session by the plugin's `SessionStart` hook — no `CLAUDE.md` wiring, no manual import. Keep them minimal and high-impact, since they cost context in every session. The file body *is* the rule; no special header.
- **Conditional conventions** are authored as **skills** (see below), not as rule files. Each carries an `**Apply when:**`-style trigger in its `description` so Claude loads it on demand only when the context matches.

### Writing an `Apply when:` trigger

A conditional skill's description must name **concrete, observable signals** that tell Claude when to load it — files, directory layout, config, or dependency-manifest entries — not vague phrasing like "when working on the backend." For example, a backend conventions skill might trigger on "the project exposes HTTP APIs or server-side endpoints — detected by a web-server framework in the dependency manifest, a `controllers/` or `routes/` directory, or a server entry point." Prefer conditional conventions over always-on rules to keep sessions lean.

## Commands vs. skills vs. agents

Pick the right primitive:

- **Commands** (`<plugin>/commands/<name>.md`) — fixed prompt templates the user invokes **manually** as `/<plugin>:<name>`. Use for deterministic workflows the user decides to run (e.g. `/common:git-commit`, `/dev:open-pr`). A command is a markdown file with optional YAML frontmatter (`description`, `argument-hint`, `allowed-tools`, `model`) and a prompt body. Keep files flat — no sub-categories.
- **Skills** (`<plugin>/skills/<name>/SKILL.md`) — **description-triggered** capabilities Claude invokes autonomously when the description matches the user's intent (and which the user can also call as `/<plugin>:<name>`). Use for context-aware logic and for conditional conventions. Frontmatter requires `name:` and `description:`; the directory name must equal `name:`. Write the description thoroughly — it is what drives autonomous triggering.
- **Agents** (`<plugin>/agents/<name>.md`) — subagents dispatched via the Agent tool with `subagent_type: "<plugin>:<name>"`. An agent runs in an **isolated context** (the parent conversation is not visible), so its body — the system prompt — must be fully self-contained. Frontmatter requires `name:` (matching the file name) and `description:` (drives dispatch), and should list `tools:` and `model:`. Agents are **not** slash commands; they return a single textual report to the parent. Use them for fresh-eyes review, heavy research, or parallelisable independent work where an isolated token budget helps.

## Bilingual triggers (Czech + English)

Every command and skill `description` must list **matched Czech and English** trigger phrases, so the capability is reachable in either language. Standardize on clean Czech (not Slovak). Keep the `/<plugin>:<name>` token in the list using the bare name. For example, for a commit command:

```
"commit", "commit message", "stage and commit", "zacommituj", "vytvoř commit", "commit zprávu", "/common:git-commit"
```

## Host-agnostic conventions

This repo does not assume any particular git host. Refer to pull/merge requests generically as **PR/MR**, and to "your git host's CLI or web UI" rather than a specific tool. Keep skill and command names host-neutral (`git-pr`, `open-pr`). Where a workflow needs the host's CLI or MCP, note that the consuming org wires it in — do not hard-code a specific host.

## MCP tool references

When a skill or command calls an MCP tool, reference it by its **bare tool name** — `jira_get_issue`, `confluence_get_page`, `atlassian_list_sites` — never with the `mcp__<server>__…` prefix.

The `mcp__<server>__` segment is the **local MCP server name**, which varies per user and org: the same Atlassian connector might be `mcp__claude_ai_Connectivity_Hub__…` for one person and `mcp__claude_ai_MBI_stage__…` for another. Hardcoding it couples the skill to one environment and silently breaks it everywhere else. The bare tool name is stable, and Claude resolves it to whatever the local server is actually called.

For the same reason, **do not list MCP tools in `allowed-tools` frontmatter.** That field matches only a literal `mcp__<server>__…` name (no server-agnostic wildcard exists), and it merely *pre-approves* a tool to skip the permission prompt — it does **not** gate function, so omitting it never blocks a call. A bare name there would match nothing.

To pre-approve the connector and skip per-tool prompts, the consuming org allows the server **once at the settings level**, where its name is known:

```json
{ "permissions": { "allow": ["mcp__<your-mcp-server>__*"] } }
```

This keeps the variable server name in each environment's settings, never baked into the shared skills.

## Change process

1. Create a branch from your main branch.
2. Make the change in the correct plugin directory (`common/`, `dev/`, or `business/`); for `common/` changes, weigh the impact on every team.
3. Update anything affected: plugin `description`s, the marketplace manifest, and the relevant README sections.
4. Open a PR/MR describing what changed and why, and get review from an owner of each affected plugin (see `CODEOWNERS`).
