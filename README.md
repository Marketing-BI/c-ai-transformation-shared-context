# Shared AI Context

A [Claude Code](https://docs.claude.com/en/docs/claude-code) plugin marketplace that gives every team a consistent, shared baseline for AI-assisted work. It ships three plugins:

| Plugin | For whom | What it carries |
|---|---|---|
| **`common`** | Everyone | Org-wide behavior and coding standards, shared git and Jira slash commands, Jira & Confluence skills, a context-pull agent, code-review standards, and a prompt/skill evaluation pipeline. |
| **`dev`** | Engineering teams | Language-agnostic software-delivery context: coding standards, conditional convention skills (backend, database, docker, testing), the Jira → analysis → implementation → review → PR workflow, planning and solution-doc skills, project `CLAUDE.md` scaffolding, and independent reviewer agents. |
| **`business`** | Commercial teams | Generic CRM operating discipline, interactive Statement of Work and Business Brief generators, ICP / customer-intelligence research, and discovery / sales-call coaching. |

The rules are **language-agnostic** — they capture universal engineering and operating principles, so teams can layer their own stack (Java, Kotlin, Swift, or anything else) on top.

This repository is consumed **as plugins** — there is no git submodule and nothing to vendor into your project repos. You point Claude Code at this repository once, enable the plugins you want, and the shared context loads automatically in every session.

## Quick start (individual developer)

Add the marketplace and enable the plugins in your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "shared-ai-context": { "source": { "source": "url", "url": "https://<your-git-host>/<your-org>/shared-ai-context.git" } }
  },
  "enabledPlugins": { "common@shared-ai-context": true, "dev@shared-ai-context": true, "business@shared-ai-context": true }
}
```

Replace the URL with the clone URL of this repository on your git host. Commit this file to the project repo so teammates pick up the same plugins; keep personal overrides in `.claude/settings.local.json` (gitignored).

Prefer to do it interactively? From inside a Claude Code session:

```
/plugin marketplace add https://<your-git-host>/<your-org>/shared-ai-context.git
/plugin install common@shared-ai-context
```

(repeat `/plugin install` for `dev@shared-ai-context` and `business@shared-ai-context` as needed). Use `/plugin` at any time to see which plugins are currently loaded.

## Enable org-wide (administrators)

To give every developer these plugins automatically — without each person editing settings — put the **same** `extraKnownMarketplaces` and `enabledPlugins` blocks shown above into Claude Code's **managed settings** file on each machine (or push it via your device-management tooling):

| Platform | Managed settings path |
|---|---|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux / WSL | `/etc/claude-code/managed-settings.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` |

Managed settings take precedence over per-user and per-project settings, so the marketplace and the plugins you list are enforced everywhere.

Pick the plugin set per audience:

- **`common`** — enable everywhere; it is the shared baseline.
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

in the project. It scaffolds a project `CLAUDE.md` tailored to that repository. Re-run it after structural changes to keep the wiring in sync without disturbing hand-written sections.

## Bilingual

Skills and commands respond to both **Czech and English** triggers, so the same capabilities are reachable in either language (e.g. "commit message" / "commit zprávu").

## Repository structure

```
.claude-plugin/marketplace.json   # Marketplace manifest: lists the three plugins
common/                           # Org-wide standards, shared commands, Jira/Confluence skills, code-review, eval pipeline
dev/                              # Software-delivery context: conventions, workflow, planning, reviewer agents
business/                         # CRM discipline, SOW/Brief generators, prospecting, sales-call coaching
CODEOWNERS                        # Review ownership (placeholder teams — update for your org)
CONTRIBUTING.md                   # How to extend this repo
```

Each top-level plugin directory holds its own `.claude-plugin/plugin.json` plus its rules, commands, skills, agents, and hooks.

## Contributing

To add or change rules, commands, skills, or agents, see [CONTRIBUTING.md](./CONTRIBUTING.md).
