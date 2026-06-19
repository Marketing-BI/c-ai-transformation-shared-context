---
description: Commit staged changes with a well-formed conventional commit message. Use for: "commit", "commit message", "stage and commit", "zacommituj", "vytvoř commit", "commit zprávu", "/common:git-commit".
argument-hint: [optional description of what to commit]
---

# Command: git-commit

## Commit Message Format

Use conventional commits:

```
<type>(<scope>): <short summary>

<optional body — explain WHY, not what>

<optional footer — references, breaking changes>
```

### Types

- `feat` — new feature or capability
- `fix` — bug fix
- `refactor` — code restructuring without behavior change
- `docs` — documentation only
- `test` — adding or updating tests
- `chore` — build, CI, dependencies, tooling
- `perf` — performance improvement
- `style` — formatting, whitespace (no logic change)

### Rules

- Summary line: imperative mood, lowercase, no period, max 72 characters.
- Scope: module or area affected (e.g., `auth`, `api`, `ui`). Optional but recommended.
- Body: wrap at 72 characters. Explain motivation and context, not the diff.
- Footer: `BREAKING CHANGE: <description>` for breaking changes. Reference issues: `Closes PROJ-123`.

## What to Stage

- Only files directly related to the change.
- Never stage: `.env`, credentials, editor configs, OS files, build artifacts.
- Review `git diff --staged` before committing.

## Commit Discipline

- One logical change per commit. If the commit message needs "and", consider splitting.
- Never commit commented-out code, debug logging, or TODO placeholders without issue references.
- Ensure the build passes before committing (run lint + type check at minimum).
