# PR/MR title + body

How the pull/merge request should look. Used by step 5 of the procedure. `<site>` throughout is the resource `url`
resolved in step 0 (setup), not a hardcoded host.

## Title (under 70 chars)

- Format: `<TICKET>: <summary>`.
- Derive `<summary>` from the **work that was actually implemented**, framed against the Jira ticket. Inputs, in order
  of weight:
  1. `jiraSummary` + `jiraDescription` from step 1 — tells you what the ticket asked for.
  2. The diff against the base branch (`git diff <default-branch>...HEAD --stat` plus
     `git log <default-branch>..HEAD --pretty=%s`) — tells you what was actually built.
  3. The pr-prep summary (`<!-- pr-prep:summary -->`) when chained, since it is the human-curated description of the
     implemented change.

  Write a present-tense imperative phrase ("add X", "fix Y", "switch Z to W"), not the raw ticket title. Strip any
  leading `<TICKET>:` / `[<TICKET>]` if you reuse text. Truncate to keep the whole title under 70 chars.
- If no Jira key exists (the user skipped step 1), fall back to a phrase derived from the diff + commit log only — no
  ticket prefix.

## Body

Full section order:

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

`Summary`, `Jira`, and `Test plan` are always present. `Version` and `Environment variables` are filled from the
pr-prep context block when chained, or **derived read-only from the branch itself** when standalone (see Section
sources). The skill works the same either way — chaining just supplies values it would otherwise compute.

- **`Environment variables`** is always included; its value is "None" when no new env vars were found.
- **`Version`** is included only when there is a bump to report — a chained value, or a version-file change already
  present on the branch diff. Standalone with no bump: omit the section rather than print a placeholder. This skill
  never bumps the version itself.

## Section sources

Fill each section from the best available source:

| Section               | Chained from `/dev:pr-prep`                | Standalone                                                                |
| --------------------- | ------------------------------------------ | ------------------------------------------------------------------------- |
| Summary               | `<!-- pr-prep:summary -->` content         | Paraphrase of `jiraSummary` + `jiraDescription` (step 1) combined with the diff / commit log. Never literal "TBD". |
| Version               | `<!-- pr-prep:version -->` content         | If the branch diff changed the project's version file, show `old → new`; otherwise omit the section. Never bump the version here. |
| Environment variables | `<!-- pr-prep:env -->` content (or "None") | Scan the branch diff (`git diff <default-branch>...HEAD`) for newly introduced env vars — same definition as `/dev:pr-prep` step 1 (new env reads, new config entries, new env-derived constants) — and list them, or "None". Read-only: do **not** propagate to the env-example file / container compose file / README. |
| Jira                  | Resolved ticket key from step 1            | Same                                                                      |
| Test plan             | Leave the checkbox for the reviewer        | Same                                                                      |

## pr-prep handoff contract

When invoked from `/dev:pr-prep`, the caller forwards a single markdown block as part of the `Skill` tool input
(alongside any `draft` token). The block is delimited by HTML comments so it's unambiguous to parse and trivially
survives prose around it:

```markdown
<!-- pr-prep:summary -->
<one-paragraph summary>
<!-- /pr-prep:summary -->

<!-- pr-prep:env -->
<env-var list, or "None">
<!-- /pr-prep:env -->

<!-- pr-prep:version -->
<old> → <new>
<!-- /pr-prep:version -->
```

Parsing rules:

- A section is **present** iff both its opening and closing markers appear in the skill input. Anything between them
  (trimmed) is the section content.
- If a marker pair is missing, treat that section as **absent** and fall back to the standalone behaviour for that row
  in the Section sources table above. Do not invent values.
- Whitespace and surrounding prose outside the marker pairs are ignored.

This skill derives env vars and version **read-only**, purely to populate the PR/MR body. It never mutates the worktree
— propagating env vars to the env-example file / container compose file / README and bumping the version file belong to
[`/dev:pr-prep`](../../pr-prep/SKILL.md). Route the user there if they want those file changes.

## Passing the body to your git host

When the host's CLI accepts the body on the command line, pass it via a quoted heredoc so tables / code fences survive
intact (the `'EOF'` quoting prevents the shell from expanding `$`, backticks, etc.):

```bash
<your-host-cli> <create-pr-or-mr-command> \
  --base "<default-branch>" \
  --title "<TICKET>: <summary>" \
  --reviewer "<handle>" \
  --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```

The exact subcommand and flag names depend on your git host's CLI — the client wires that here. The web UI is an equally
valid path; the heredoc only matters when the body goes through a shell.
