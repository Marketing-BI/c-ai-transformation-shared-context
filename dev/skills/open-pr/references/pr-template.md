# PR/MR title + body — fill-in skeleton

Concrete fill-in skeleton for step 5. The **title and description conventions are owned by**
[`/common:git-pr`](../../../../common/commands/git-pr.md) — follow it for the title format and the base body structure.
This file does not redefine those conventions; it only maps each section to its source and adds the project-specific
`Version`, `Environment variables`, and `Jira` fields on top of the `/common:git-pr` template.

`<site>` throughout is the resource `url` resolved in step 0 (setup), not a hardcoded host.

## Title

Follow `/common:git-pr`'s title rule: `<type>(<scope>): <summary>`, under 72 chars. Derive `<summary>` from the **work
that was actually implemented**, framed against the Jira ticket. Inputs, in order of weight:

1. `jiraSummary` + `jiraDescription` from step 1 — tells you what the ticket asked for.
2. The diff against the base branch (`git diff <default-branch>...HEAD --stat` plus
   `git log <default-branch>..HEAD --pretty=%s`) — tells you what was actually built.
3. The Phase-1 change summary (step P5) when Phase 1 ran — the human-curated description of the implemented change.

Write a present-tense imperative phrase ("add X", "fix Y", "switch Z to W"), not the raw ticket title. Prefix per your
project convention (e.g. include the `<TICKET>` if your team puts it in the title). If no Jira key exists (the user
skipped step 1), fall back to a phrase derived from the diff + commit log only.

## Body

Body structure follows `/common:git-pr`, extended with `Version`, `Environment variables`, and `Jira` fields:

```markdown
## Summary

<one-paragraph summary of what changed and why>

## Version

<old> → <new>

## Environment variables

<list of new env vars, or "None">

## Jira

[<TICKET>](https://<site>/browse/<TICKET>)

## Test plan

- [ ] <fill in>
```

`Summary`, `Jira`, and `Test plan` are always present.

- **`Environment variables`** is always included; its value is "None" when no new env vars were found.
- **`Version`** is included only when there is a bump to report. Standalone (Phase 1 skipped) with no bump: omit the
  section rather than print a placeholder. Phase 2 never bumps the version itself.

## Section sources

Fill each section from the best available source. When Phase 1 ran, the values come straight from it; when Phase 1 was
skipped (e.g. someone ran Phase 2 standalone), derive them read-only from the branch.

| Section               | From Phase 1 (steps P1–P5)            | Phase 1 skipped (read-only from branch)                                                                          |
| --------------------- | ------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Summary               | The step-P5 change summary            | Paraphrase of `jiraSummary` + `jiraDescription` (step 1) combined with the diff / commit log. Never literal "TBD". |
| Version               | `old → new` from step P2              | If the branch diff changed the project's version file, show `old → new`; otherwise omit the section. Never bump the version here. |
| Environment variables | The env-var list from step P1 (or "None") | Scan the branch diff (`git diff <default-branch>...HEAD`) for newly introduced env vars (new env reads, new config entries, new env-derived constants) and list them, or "None". Read-only: do **not** propagate to the env-example file / container compose file / README. |
| Jira                  | Resolved ticket key from step 1       | Same                                                                                                            |
| Test plan             | Leave the checkbox for the reviewer   | Same                                                                                                            |

Phase 2 derives env vars and version **read-only**, purely to populate the PR/MR body. The worktree mutations
(propagating env vars to the env-example file / container compose file / README and bumping the version file) belong to
Phase 1 — run the full `/dev:open-pr` (not `prep-only` skipped) if those file changes are wanted.

## Passing the body to your git host

When the host's CLI accepts the body on the command line, pass it via a quoted heredoc so tables / code fences survive
intact (the `'EOF'` quoting prevents the shell from expanding `$`, backticks, etc.):

```bash
<your-host-cli> <create-pr-or-mr-command> \
  --base "<default-branch>" \
  --title "<type>(<scope>): <summary>" \
  --reviewer "<handle>" \
  --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```

The exact subcommand and flag names depend on your git host's CLI — the client wires that here. The web UI is an equally
valid path; the heredoc only matters when the body goes through a shell.
