---
name: open-pr
argument-hint: "[reviewer] [draft]"
description: |
  Use when the user wants to push the current branch and open a pull/merge request on their git host in one step,
  with the chosen reviewer requested. Resolves a Jira ticket key from the current branch (or recent commits), resolves
  a reviewer from the project's team mapping (or by asking the user), pushes the branch if needed, opens the PR/MR on
  your git host with that person requested as reviewer, and optionally sets your issue tracker's reviewer/QA field if
  your team wires one. Host-agnostic — the client wires their git host's CLI or MCP. Used directly or chained from
  /dev:pr-prep. Never transitions Jira status — use /common:jira-update for that.

  English triggers: "open pr", "open mr", "create pr", "create mr", "open a pull request", "open a merge request",
  "ready for review", "push and open pr", "/dev:open-pr", "/dev:open-pr <reviewer>", "/dev:open-pr <reviewer> draft"

  České spouštěče: "otevři pr", "otevři mr", "vytvoř pr", "vytvoř mr", "otevři pull request", "otevři merge request",
  "připraveno k review", "pushni a otevři pr", "/dev:open-pr", "/dev:open-pr <reviewer>", "/dev:open-pr <reviewer> draft"

  Do NOT apply when: the user only wants the pre-PR/MR checklist without opening anything (use /dev:pr-prep with no
  create token), only wants to write commit messages (use /common:git-commit), or only wants to move a Jira ticket
  (use /common:jira-update).
user-invocable: true
allowed-tools:
  Read, Bash, Glob, Grep, Skill, AskUserQuestion, mcp__atlassian__*
---

# Open PR/MR

Push the current branch and open a pull/merge request on your git host in a single flow, with the chosen reviewer
requested. Optionally also set a reviewer/QA field on the linked issue if your team uses one.

## Host integration (configure this)

This skill is **git-host-agnostic**. It describes the *actions* — "push the branch", "open a PR/MR with a reviewer
requested", "check for an existing PR/MR" — and leaves the concrete command to your environment. Wire one of these in
your project and use it for every host action below:

- **Your git host's CLI** (the command-line tool for your host), or
- **A git-host MCP server**, or
- **The host's web UI** (manual fallback — the skill prints what to fill in).

Whenever a step says "open the PR/MR" or "check for an existing PR/MR", run it through whatever you wired here. Pass the
PR/MR body via a quoted heredoc when the CLI takes it on the command line, so tables / code fences survive intact (see
[`references/pr-template.md`](references/pr-template.md)).

## Issue tracker (Jira) integration

The Jira ticket key drives the PR/MR title and the Jira link in the body. Jira reads use the Atlassian MCP
(`mcp__atlassian__*`). Resolve the right `cloudId` once at the start of the run (see Setup) and reuse it for every
Atlassian MCP call.

- **Atlassian site** — your Jira site host (e.g. `«your-jira-site»`), used only to pick the right resource from
  `getAccessibleAtlassianResources`; never passed as `cloudId` directly.
- **Optional reviewer/QA field** — if your team tracks the reviewer/QA on the issue, set that field too (step 6). This
  is **opt-in and configurable**: put your tracker's field id in `references/team-mapping.md`. With no field configured,
  skip that step entirely. **No custom field is hardcoded here.**

## Arguments

```text
/dev:open-pr [reviewer] [draft]
```

- `reviewer` — optional. Matches the team mapping by **email**, **git-host handle**, or case-insensitive **substring on
  display name**.
- `draft` — optional flag → opens the PR/MR as a draft (use your host's draft option).

Token order does not matter. If `reviewer` is omitted or matches nothing, prompt the user via `AskUserQuestion` using
entries from the [team mapping](references/team-mapping.md).

## Team mapping

The reviewer roster (email ↔ git-host handle ↔ display name) lives in
[`references/team-mapping.md`](references/team-mapping.md) as a **placeholder template the client fills in with their own
team**. Edit that table to add or remove people. If your tracker has a reviewer/QA account id, the skill resolves it at
runtime by looking the person up in your issue tracker by email (via the Atlassian MCP account-lookup call) — it is not
stored in the table.

## Procedure

Copy this checklist and check items off as you go:

```text
- [ ] 0. Setup: resolve Jira cloudId + current git-host user
- [ ] 1. Resolve Jira ticket key (and verify it exists)
- [ ] 2. Resolve reviewer (team mapping → ask if unknown), excluding self
- [ ] 3. Ensure branch is pushed
- [ ] 4. Check for an existing PR/MR on this branch
- [ ] 5. Build PR/MR title + body, confirm, create
- [ ] 6. (Optional) Set the issue tracker's reviewer/QA field — only if configured
- [ ] 7. Print final output (PR/MR URL + Jira link)
```

### 0. Setup

Resolve two things up front and keep them as variables for the rest of the run:

1. **`cloudId`** — call `mcp__atlassian__getAccessibleAtlassianResources` and pick the resource whose `url` matches your
   Jira site. Use that resource's `id` as `cloudId` for every later Atlassian MCP call. If no matching resource is
   returned, halt with:

   ```text
   No accessible Atlassian resource for your Jira site. Re-auth the Atlassian MCP and retry.
   ```

2. **`currentUser`** — the current user's handle on your git host (query it via your host's CLI/MCP, e.g. a "whoami" /
   current-user lookup). Used in step 2 to prevent self-review. If it can't be resolved (host not authenticated), halt
   and tell the user to authenticate their git host first.

### 1. Resolve Jira ticket key

1. Run `git rev-parse --abbrev-ref HEAD` and search for `[A-Z]+-\d+` in the branch name.
2. If none, run `git log -20 --pretty=%s` and search each subject for `[A-Z]+-\d+`.
3. If still none, ask the user via `AskUserQuestion` (free-form, expect a key like `PROJ-123`).

Halt with a clear message if the user cannot provide a key — do not invent one.

**Verify the key exists** before going further:

```yaml
mcp__atlassian__getJiraIssue
  cloudId: <cloudId from step 0>
  issueIdOrKey: <TICKET>
  fields: ["summary", "description"]
```

- **Not found** → ask the user via `AskUserQuestion` to confirm the key or supply the right one, then re-verify. Halt if
  the user can't produce a valid key. Do not open a PR/MR pointing at a ticket that does not exist.
- **Found** → keep `jiraSummary` and `jiraDescription` in scope. They drive the PR/MR title in step 5 and the Summary
  section of the body when no pr-prep context is provided.

### 2. Resolve reviewer

**Exclude self.** Filter the team mapping to rows where the git-host handle `!= currentUser` from step 0 before doing
any matching or prompting — most hosts reject a PR/MR that requests its own author as reviewer, and self-review defeats
the point.

1. If a `reviewer` arg was passed, match against the **filtered** team mapping in this order: exact email → exact
   git-host handle → case-insensitive substring on display name.
2. If the arg matches multiple rows, prompt the user to disambiguate.
3. If the arg matches the current user (post-filter: zero rows), tell the user "can't review your own PR/MR" and
   re-prompt from the filtered mapping.
4. If no arg, or no match, prompt via `AskUserQuestion` listing up to 4 mapping entries. When the filtered mapping has
   more than 4 entries, also offer "Other — type a name/email" and re-resolve against the mapping using their input.
5. With the resolved row (`email`, git-host `handle`, `displayName`), you have everything needed to request the reviewer
   on the PR/MR in step 5.

   **Only if** your team wires the optional issue-tracker reviewer/QA field (step 6), also resolve the tracker account
   id now — look the person up in your issue tracker by email with the Atlassian MCP account-lookup call:

   ```yaml
   <atlassian-mcp-account-lookup>
     cloudId: <cloudId from step 0>
     query: <email>
   ```

   - Multiple results → pick the one whose tracker email exactly matches `<email>`. If still ambiguous, prompt the user.
   - Zero results → the tracker has no account for this person; skip the optional field update in step 6 (the PR/MR
     reviewer request still proceeds) and note it for the user.

Output of this step: `{ email, handle, displayName }` (plus `jiraAccountId` if the optional field is configured).

### 3. Ensure branch is pushed

1. Check upstream with `git rev-parse --abbrev-ref --symbolic-full-name @{u}`.
2. If no upstream, run `git push -u origin <branch>`.
3. If upstream exists but is behind, run `git push`.

Never use `--force` or `--no-verify`. Surface push errors and halt — do not proceed to PR/MR creation.

### 4. Check for an existing PR/MR on this branch

Ask your git host (via its CLI/MCP) whether an open PR/MR already exists for the current branch, and capture its URL,
number, draft flag, and state.

- **PR/MR exists and is open** → ask via `AskUserQuestion`:
  - "Update reviewer (+ tracker field if configured) only" → skip to step 6 with the existing PR/MR URL, after
    requesting the reviewer on the existing PR/MR.
  - "Cancel" → exit cleanly.
- **No PR/MR / closed PR/MR** → proceed.

### 5. Build PR/MR title + body, confirm, create

Construct the title and body per [`references/pr-template.md`](references/pr-template.md) — title rules, the body
template, the `Version` / `Environment variables` sections (from the pr-prep context block when chained, otherwise
derived read-only from the branch), the section-sources table, and the pr-prep handoff contract (the `<!-- pr-prep:* -->`
markers + parsing rules). Use the resource `url` from step 0 as `<site>` for the Jira link.

This skill is read-only with respect to the worktree — it never propagates env vars or bumps the version file. Those
mutations belong to [`/dev:pr-prep`](../pr-prep/SKILL.md).

**Confirmation gate**: show the full title and body exactly as they will appear and ask `Create PR/MR now? (yes / edit /
cancel)`:

- `yes` → continue.
- `edit` → apply the user's requested changes, then re-confirm.
- `cancel` → stop without creating the PR/MR.

**Create the PR/MR** through your git host's CLI/MCP (or print the fields for the web UI). Base branch = the repo's
default branch (query it from your host, or use `git remote show origin` / `git symbolic-ref refs/remotes/origin/HEAD`).
Request the resolved reviewer's git-host `handle` as a reviewer, and apply the draft option if `draft` was passed. When
the host CLI takes the body on the command line, pass it via a quoted heredoc so tables / code fences survive:

```bash
git push -u origin <branch>            # if not already pushed in step 3
<your-host-cli> <create-pr-or-mr-command> \
  --base "<default-branch>" \
  --title "<TITLE>" \
  --reviewer "<handle>" \
  [--draft] \
  --body "$(cat <<'EOF'
<BODY>
EOF
)"
```

The exact subcommand and flag names depend on your git host's CLI — the client wires that here. The web UI is an equally
valid path; the heredoc only matters when the body goes through a shell. Capture the PR/MR URL from the result.

### 6. (Optional) Set the issue tracker's reviewer/QA field

**Only if** your team has configured a reviewer/QA field id in `references/team-mapping.md`. With no field configured,
skip this step entirely — the reviewer is already requested on the PR/MR, which is enough for most teams.

If configured, set it with the field id from your config and the `jiraAccountId` resolved in step 2:

```yaml
mcp__atlassian__editJiraIssue
  cloudId: <cloudId from step 0>
  issueIdOrKey: <TICKET>
  fields:
    <your-configured-field-id>:
      accountId: <jiraAccountId>
```

**If the edit fails after the PR/MR has already been opened**, do **not** roll back the PR/MR. Print the Jira error and
the manual retry so the user can fix the ticket from their end.

### 7. Final output

Print the summary defined in [`references/final-output.md`](references/final-output.md) (PR/MR URL + Jira link; and, when
the optional field was set, a line noting the reviewer/QA was set to `<displayName>`). `<site>` is the `url` from the
resource resolved in step 0.

## Edge cases

See [`references/edge-cases.md`](references/edge-cases.md) for the full failure-mode table (auth/resource failures,
reviewer-resolution problems, push/PR-MR/Jira errors, existing-PR/MR and cancel handling).

## Notes

- Never pushes to `main` / `master` or any protected branch directly.
- Never amends commits, force-pushes, or skips hooks.
- Status transitions are out of scope; use `/common:jira-update` if you also want to move the ticket.
- The reviewer/QA tracker field is **opt-in** — nothing is hardcoded; configure it (or don't) in `references/team-mapping.md`.
