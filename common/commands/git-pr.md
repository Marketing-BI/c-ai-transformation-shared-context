---
description: Open a pull/merge request (PR/MR) on your git host with a consistent structure. Use for: "open PR", "create pull request", "raise MR", "otevři PR", "vytvoř pull request", "/common:git-pr".
argument-hint: [optional ticket ID or description]
---

# Command: git-pr

## Branch Naming

```
<type>/<ticket-id>-<short-description>
```

Examples: `feat/PROJ-123-user-auth`, `fix/PROJ-456-null-pointer`, `chore/PROJ-789-update-deps`

## Pull/Merge Request Title

- Follow the same format as commit messages: `<type>(<scope>): <summary>`
- Keep under 72 characters.

## Pull/Merge Request Description

### Template

```markdown
## Summary

<!-- 1-3 bullet points: what changed and why -->

## Changes

<!-- Detailed list of changes, grouped logically -->

## Testing

<!-- How was this tested? What should reviewers verify? -->

## Related

<!-- Links to tickets, related PRs/MRs, design docs -->
```

### Rules

- Every PR/MR must reference a ticket or issue.
- Include screenshots/recordings for UI changes.
- Call out anything that needs special attention from reviewers.
- Mark draft PR/MRs as Draft until ready for review.

## PR/MR Discipline

- Keep PR/MRs small and focused — one feature or fix per PR/MR.
- If a PR/MR exceeds ~400 lines of meaningful changes, consider splitting.
- Rebase on the target branch before requesting review (no merge commits in feature branches).
- All CI checks must pass before merging.
- Require at least one approval before merging.
- Delete the branch after merge.

## Review Checklist

- Code follows project conventions and shared context rules
- No secrets, credentials, or PII in the diff
- Tests cover the change (new tests for new behavior, regression tests for fixes)
- No unrelated changes bundled in
- Database migrations are reversible
- API changes are backward-compatible or versioned

## Opening a PR/MR

Use your git host's CLI or web UI to open the PR/MR. Wire up the specific CLI or MCP tool for your git host in your project's `.claude/settings.json` — for example, a command-line tool for your git host, or an MCP server that exposes PR/MR creation. Once wired, invoke it from here with the title and description generated above.
