# Shared AI Context

A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin marketplace that gives every team a consistent, shared baseline for AI-assisted work. It ships four plugins:

| Plugin | For whom | What it carries |
|---|---|---|
| **`common`** | Everyone | Org-wide behavior and coding standards, the always-on context-index rule (its `SessionStart` hook points Claude at the org's `context__get_index` MCP tool — the navigation index of where company info lives — and tells it to call that tool first for company-specific questions), shared git and Jira slash commands, Jira & Confluence skills, a context-pull agent, code-review standards, and a prompt/skill evaluation pipeline. |
| **`dev`** | Engineering teams | Language-agnostic software-delivery context: coding standards, conditional convention skills (backend, database, docker, testing), the Jira → analysis → implementation → review → PR workflow, planning and solution-doc skills, project `CLAUDE.md` scaffolding, and independent reviewer agents. |
| **`business`** | Commercial teams | Generic CRM operating discipline, interactive Statement of Work and Business Brief generators, ICP / customer-intelligence research, and discovery / sales-call coaching. |
| **`context`** | Index maintainers | Building and maintaining the company context index. Two skills: `context-create` (build the navigation index page) and `context-validate` (audit it for dead links / drift). The always-on rule that makes Claude *use* the index lives in `common`, so consumers don't need this plugin. |

The rules are **language-agnostic** — they capture universal engineering and operating principles, so teams can layer their own stack (Java, Kotlin, Swift, or anything else) on top.

This repository is consumed **as plugins** — there is no git submodule and nothing to vendor into your project repos. You point Claude Code at this repository once, enable the plugins you want, and the shared context loads automatically in every session.

## Install

Enabling the marketplace and plugins comes down to putting the **same two keys** — `extraKnownMarketplaces` (the marketplace source) and `enabledPlugins` (which plugins to turn on) — into a settings file. *Which* file depends on who you are enabling them for. The three tiers below are **alternatives, not steps** — pick the one that matches your situation.

The block to add (used by every tier) is:

```json
{
  "extraKnownMarketplaces": {
    "shared-ai-context": { "source": { "source": "url", "url": "https://<your-git-host>/<your-org>/shared-ai-context.git" } }
  },
  "enabledPlugins": { "common@shared-ai-context": true, "dev@shared-ai-context": true, "business@shared-ai-context": true, "context@shared-ai-context": true }
}
```

The marketplace `url` is host-agnostic: it accepts either an `https://…` clone URL or an SSH one (`git@<your-git-host>:<your-org>/shared-ai-context.git`). Trim `enabledPlugins` to the plugins you actually want.

### Tier 1 — Individual developer

*Use this when you just want the plugins for yourself, across all your projects.*

Add the block above to your **user-level** settings at **`~/.claude/settings.json`**. Keep any personal tweaks in **`~/.claude/settings.local.json`**.

Prefer to do it interactively? From inside a Claude Code session:

```
/plugin marketplace add https://<your-git-host>/<your-org>/shared-ai-context.git
/plugin install common@shared-ai-context
/plugin install dev@shared-ai-context
/plugin install business@shared-ai-context
```

The `add` URL is host-agnostic too — `https://…` or `git@<your-git-host>:…` both work. Use `/plugin` at any time to see which plugins are currently loaded.

### Tier 2 — A whole team on a project

*Use this when you want everyone working in a particular repository to get the same plugins.*

Commit the block above in the project's **`.claude/settings.json`**, so teammates inherit the marketplace and plugins when they open the repo. Keep personal overrides in **`.claude/settings.local.json`** (gitignored). This is the only tier where committing a settings file is the right move.

### Tier 3 — Org-wide (recommended for rollout)

*Use this when you want every developer to get the plugins automatically, with no per-developer action.*

Administrators put the **same** block into Claude Code's **managed settings** file on each machine (or push it via device-management tooling):

| Platform | Managed settings path |
|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux / WSL | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

Managed settings take precedence over per-user and per-project settings, so the marketplace and the plugins you list are enforced everywhere — no individual developer needs to touch their own settings.

Pick the plugin set per audience:

- **`common`** — enable everywhere; it is the shared baseline and carries the context-index rule that points Claude at the company context index.
- **`context`** — enable only for people who build / maintain the context index.
- **`dev`** — enable for engineering teams.
- **`business`** — enable for commercial teams.

(Or simply enable all three org-wide if you prefer one uniform configuration.)

## How rules load

You do **not** wire anything into a project's `CLAUDE.md` for the shared rules to apply. Once a plugin is enabled:

- **Always-on rules** are injected at the start of every session by the plugin's `SessionStart` hook. The hook needs either `jq` or `python3` on the developer's `PATH` to assemble the rules — both are common, but make sure one is available.
- **Conditional conventions** load as **skills**: Claude pulls them in on demand when the situation matches the skill's description (for example, the backend conventions when it detects an HTTP API), so sessions stay lean.

## Per-project context

Shared rules cover the org. For repo-specific context (stack, architecture, key commands), run:

```
/dev:claude-md
```

in the project. It scaffolds a project-overview `CLAUDE.md` (stack, architecture, key commands) tailored to that repository. The shared rules do **not** depend on it — they load via the plugin's `SessionStart` hook and on-demand skills, not through imports in `CLAUDE.md`. Re-run it after structural changes to refresh the project overview without disturbing hand-written sections.

## Bilingual

Skills and commands respond to both **Czech and English** triggers, so the same capabilities are reachable in either language (e.g. "commit message" / "commit zprávu").

## Repository structure

```
.claude-plugin/marketplace.json   # Marketplace manifest: lists the three plugins
common/                           # Org-wide standards + context-index rule (SessionStart hook → context__get_index), shared commands, Jira/Confluence skills, code-review, eval pipeline
dev/                              # Software-delivery context: conventions, workflow, planning, reviewer agents
business/                         # CRM discipline, SOW/Brief generators, prospecting, sales-call coaching
context/                          # context-create / context-validate skills (for index maintainers)
CODEOWNERS                        # Review ownership (placeholder teams — update for your org)
CONTRIBUTING.md                   # How to extend this repo
```

Each top-level plugin directory holds its own `.claude-plugin/plugin.json` plus its rules, commands, skills, agents, and hooks.

## Contributing

To add or change rules, commands, skills, or agents, see [CONTRIBUTING.md](./CONTRIBUTING.md).
