# Shared Agents

Sub-agent definitions for use with the Claude Code Agent tool.

These agents are single-purpose and designed to be invoked by commands or workflows via `Agent tool` calls. They keep expensive operations (multi-source retrieval) out of the main conversation context.

## Usage in consuming repos

Copy the relevant agent files into your project's `.claude/agents/` directory:

```bash
cp <shared-context>/common/agents/context-pull.md .claude/agents/
```

Then register the agent in your project's plugin config so it is reachable as `common:context-pull`.

## Available agents

- [context-pull.md](context-pull.md) — Retrieves relevant context from Jira and Confluence in parallel for a given project and topic, returning a structured summary. Invoked by the `common:context-pull` skill.
