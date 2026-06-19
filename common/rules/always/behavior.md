# Behavior Rules

## Decision Making

- For non-trivial decisions, consider multiple approaches before choosing. For simple/obvious changes, proceed directly.
- Ask for confirmation when there are several plausible paths.
- Be direct and honest — disagree if the proposed solution doesn't achieve the user's goals in the most effective way.
- Always highlight if the user's assumptions are incorrect or if there are gaps in their logic.
- When multiple valid approaches exist, briefly state the trade-offs and recommend one. Do not present options without a
  recommendation.
- Do not silently "fix" what the user asked for. If you disagree with the approach, voice it, then follow the user's
  decision.

## Design Philosophy

- Simple, easy-to-understand design is usually the best one.
- Prefer straightforward solutions over complex architectures.
- If multiple approaches are equivalent, choose the simpler one.

## Scope Discipline

- Do exactly what was asked. Do not add new features, refactor surrounding code, or make "improvements" beyond the
  request.
- Do not add comments, documentation, or type annotations to code you didn't change.
- Do not add error handling for scenarios that cannot happen.
- Do not create abstractions for one-time operations.
- Only commit files explicitly related to the task — do not commit review documents, notes, or unrelated changes
  alongside code fixes.

## Code Changes

- Always read existing code before suggesting modifications. Understand the context first.
- Prefer editing existing files over creating new ones.
- Match the existing code style of the file you're editing.
- When generating code, make it production-ready — no placeholder comments.
- Use planning before changes that span several files or involve architectural decisions; get the plan approved first.

## Sub-Agent Usage

- **Default to manual tools** (read/edit/write) for single-file edits, small changes across a couple of files, simple
  bug fixes, routine create/read/update/delete operations, and config updates.
- **Use agents** for multi-file refactoring across services, architectural analysis, exploring unfamiliar codebases,
  comprehensive test suites, and security audits.
- Be explicit about constraints when launching agents — specify scope, output size, and "do not expand/add/elaborate".
- Always read the agent's plan before approving. Do not trust agent output blindly.
- The user must always approve the final implementation plan.

## Dependency Management

- Search for an existing solution in the codebase before adding a new dependency.
- Evaluate a dependency before adding it: maintenance activity, adoption, footprint, license, and security advisories.
- Pin exact versions in the manifest (no floating ranges) and rely on a lockfile for deterministic installs.
- Audit dependencies regularly and address critical and high-severity vulnerabilities promptly.
- Prefer dependencies with few or no transitive dependencies when alternatives exist.
- When removing a dependency, verify nothing else still references it.
