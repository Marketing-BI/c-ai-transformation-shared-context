---
name: open-pr
argument-hint: "[reviewer] [draft] [prep-only]"
description: |
  Use when the user wants to get changes ready for review and open a pull/merge request on their git host — the whole
  pre-PR/MR flow in one skill. Phase 1 runs the post-implementation checklist (detect new environment variables and
  propagate them to the env-example file / container compose file / README, bump the project's version file, append a
  CHANGELOG entry, review CLAUDE.md, and summarize the changes). Phase 2 resolves a Jira ticket key from the current
  branch (or recent commits), resolves a reviewer from the project's team mapping (or by asking the user), pushes the
  branch, opens the PR/MR on your git host with that person requested as reviewer. Run `prep-only` to stop after
  Phase 1 (checklist, no push, no PR/MR). Host-agnostic and language-agnostic — the client wires their git host's CLI or MCP. Defers to /common:git-pr
  for the PR/MR title/description conventions. Never transitions Jira status — use /common:jira-update for that.

  English triggers: "prep pr", "prep mr", "prepare pr", "prepare mr", "pre-pr checklist", "ready for pr", "ready for mr",
  "open pr", "open mr", "create pr", "create mr", "open a pull request", "open a merge request", "push and open pr",
  "ready for review", "/dev:open-pr", "/dev:open-pr <reviewer>", "/dev:open-pr <reviewer> draft",
  "/dev:open-pr prep-only"

  České spouštěče: "připrav pr", "připrav mr", "příprava na pr", "checklist před pr", "připraveno k review", "otevři pr",
  "otevři mr", "vytvoř pr", "vytvoř mr", "otevři pull request", "otevři merge request", "pushni a otevři pr",
  "/dev:open-pr", "/dev:open-pr <reviewer>", "/dev:open-pr <reviewer> draft", "/dev:open-pr prep-only"

  Do NOT apply when: the user only wants to write commit messages (use /common:git-commit), or only wants to move a Jira
  ticket (use /common:jira-update).
user-invocable: true
allowed-tools:
  Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
---

# Open PR/MR

Get the current branch ready for review and open a pull/merge request on your git host in a single flow. Two phases:

- **Phase 1 — pre-flight checklist** (steps P1–P5): propagate new env vars, bump the version, append a CHANGELOG entry,
  review `CLAUDE.md`, and produce a change summary. Local file edits only — no push, no PR/MR.
- **Phase 2 — push + open** (steps 0–6): resolve the Jira key + reviewer, push the branch, and open the PR/MR with the
  reviewer requested. The Phase-1 summary feeds the PR/MR body directly.

Run with `prep-only` to stop after Phase 1.

This skill is **language- and host-agnostic**. In Phase 1 the file names below (env-example file, container compose
file, version file, changelog) are *roles*, not a fixed ecosystem — map each to whatever your project actually uses.

## Arguments

```text
/dev:open-pr [reviewer] [draft] [prep-only]
```

- `reviewer` — optional. Matches the team mapping by **email**, **git-host handle**, or case-insensitive **substring on
  display name**. Only used in Phase 2.
- `draft` — optional flag → opens the PR/MR as a draft (use your host's draft option). Only used in Phase 2.
- `prep-only` — optional flag → run **Phase 1 only** and stop (checklist + summary; never pushes, never opens a PR/MR).

Token order does not matter. With `prep-only`, the skill ends after step P5. Otherwise it runs Phase 1 then Phase 2. If
`reviewer` is omitted or matches nothing, prompt the user via `AskUserQuestion` using entries from the
[team mapping](references/team-mapping.md).

## Host integration (configure this)

Phase 2 is **git-host-agnostic**. It describes the *actions* — "push the branch", "open a PR/MR with a reviewer
requested", "check for an existing PR/MR" — and leaves the concrete command to your environment. Wire one of these in
your project and use it for every host action below:

- **Your git host's CLI** (the command-line tool for your host), or
- **A git-host MCP server**, or
- **The host's web UI** (manual fallback — the skill prints what to fill in).

Whenever a step says "open the PR/MR" or "check for an existing PR/MR", run it through whatever you wired here. Pass the
PR/MR body via a quoted heredoc when the CLI takes it on the command line, so tables / code fences survive intact (see
[`references/pr-template.md`](references/pr-template.md)).

## Issue tracker (Jira) integration

The Jira ticket key drives the PR/MR title and the Jira link in the body. Jira reads use the Hub's Atlassian
connector, which runs against the connection's **active site** — you
do not pass a `cloudId`. The default active site is normally correct.

- **Atlassian site** — if your team works across more than one Atlassian site, select it once at the start of Phase 2
  (see Setup) with `atlassian_set_active_site`; otherwise just call the tools.

## Team mapping

The reviewer roster (email ↔ git-host handle ↔ display name) lives in
[`references/team-mapping.md`](references/team-mapping.md) as a **placeholder template the client fills in with their own
team**. Edit that table to add or remove people.

---

## Phase 1 — Pre-flight checklist

Run this after implementation is complete, before push. It mutates only local files. With `prep-only`, the skill stops
at the end of this phase.

### P1. Check for new environment variables

Scan all changed files for any newly introduced environment variables — new reads of the process environment, new
entries in config files, or new constants derived from environment variables. List them in the terminal:

- Variable name
- Purpose
- Default value (if any)

If new env vars exist, propagate them to whichever of these the project keeps:

- The **env-example file** (the committed template of expected env vars) — add each with a sensible default or a `???`
  placeholder.
- The **container compose file**'s environment section, if one exists.
- The **README** env-vars section, if it exists and documents env vars.

If no new env vars were introduced, state that explicitly.

### P2. Update version

- Read the current version from the project's **version file** (the manifest/descriptor that carries the project
  version — whatever your ecosystem uses).
- Determine the bump type based on the changes, following semantic-versioning intent:
  - **patch**: bug fixes, minor tweaks
  - **minor**: new features, non-breaking additions
  - **major**: breaking changes
- Apply the bump. Prefer the ecosystem's own tooling so any lockfile / companion file stays in sync **without** creating
  a git commit or tag. If no such tool is available, edit the version file directly (and update any lockfile/companion
  file that mirrors the version so they match).

If the project has no version file, note that and skip this step. Keep `old → new` for the PR/MR body (step 5).

### P3. Update changelog

- Add a new version section to the **changelog** (e.g. `CHANGELOG.md`) following the existing format.
- Include the Jira ticket key if available (from the branch name or conversation context).
- Keep entries concise — one bullet per logical change.

If the project keeps no changelog, note that and skip this step.

### P4. Check CLAUDE.md

Review whether the changes affect anything documented in `CLAUDE.md` (and any rule files it references):

- New architectural patterns or modules
- New conventions or constraints
- Changes to existing documented behavior

If updates are needed, apply them. If not, state that no updates are needed.

### P5. Summarize changes

Provide a concise description of all changes made in this session — what was added/changed and why. This is the change
summary that feeds the **Summary** section of the PR/MR body in Phase 2 (step 5). Keep the env-var list (P1) and the
version `old → new` (P2) in scope too — they populate the **Environment variables** and **Version** sections of the body.

> **`prep-only` stops here.** Use `/common:git-commit` to commit the files Phase 1 changed (env files, version file,
> changelog, `CLAUDE.md`) on the current branch; use `/common:jira-update` if you also want to move the ticket. Re-run
> `/dev:open-pr` (without `prep-only`) when you're ready to push and open the PR/MR.

---

## Phase 2 — Push + open the PR/MR

Push the current branch and open a pull/merge request on your git host, with the chosen reviewer requested. The change
summary, env-var list, and version bump from Phase 1 feed the PR/MR body directly.

Copy this checklist and check items off as you go:

```text
- [ ] 0. Setup: confirm active Atlassian site (only if multi-site) + current git-host user
- [ ] 1. Resolve Jira ticket key (and verify it exists)
- [ ] 2. Resolve reviewer (team mapping → ask if unknown), excluding self
- [ ] 3. Ensure branch is pushed
- [ ] 4. Check for an existing PR/MR on this branch
- [ ] 5. Build PR/MR title + body, confirm, create
- [ ] 6. Print final output (PR/MR URL + Jira link)
```

### 0. Setup

Resolve up front and keep for the rest of the run:

1. **Active Atlassian site** — Hub Atlassian tools use the connection's active site; you don't pass a `cloudId`. If your
   team works across multiple sites and the default isn't the one holding this ticket, call
   `atlassian_list_sites` and switch with
   `atlassian_set_active_site` (its `cloud_id`). Otherwise skip this.

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
jira_get_issue
  issue_key: <TICKET>
```

- **Not found** → ask the user via `AskUserQuestion` to confirm the key or supply the right one, then re-verify. Halt if
  the user can't produce a valid key. Do not open a PR/MR pointing at a ticket that does not exist.
- **Found** → keep `jiraSummary` and `jiraDescription` in scope. They drive the PR/MR title in step 5 and the Summary
  section of the body when no Phase-1 summary is available.

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

Output of this step: `{ email, handle, displayName }`.

### 3. Ensure branch is pushed

1. Check upstream with `git rev-parse --abbrev-ref --symbolic-full-name @{u}`.
2. If no upstream, run `git push -u origin <branch>`.
3. If upstream exists but is behind, run `git push`.

Never use `--force` or `--no-verify`. Surface push errors and halt — do not proceed to PR/MR creation.

### 4. Check for an existing PR/MR on this branch

Ask your git host (via its CLI/MCP) whether an open PR/MR already exists for the current branch, and capture its URL,
number, draft flag, and state.

- **PR/MR exists and is open** → ask via `AskUserQuestion`:
  - "Update reviewer only" → request the reviewer on the existing PR/MR, then go to final output.
  - "Cancel" → exit cleanly.
- **No PR/MR / closed PR/MR** → proceed.

### 5. Build PR/MR title + body, confirm, create

The PR/MR title and description conventions are owned by [`/common:git-pr`](../../../common/commands/git-pr.md) — it is
the single source of truth for the title format (`<type>(<scope>): <summary>`, under 72 chars) and the body structure.
Follow it. [`references/pr-template.md`](references/pr-template.md) is the concrete fill-in skeleton that *follows*
`/common:git-pr` — it maps each section to its source (the Phase-1 summary / env-var list / version bump, or values
derived read-only from the branch when Phase 1 was skipped) and adds the `Version`, `Environment variables`, and `Jira`
fields. Use the resource `url` from step 0 as `<site>` for the Jira link.

Fill the body from Phase 1 when available:

- **Summary** ← the Phase-1 change summary (step P5). When Phase 1 was skipped, paraphrase `jiraSummary` +
  `jiraDescription` (step 1) combined with the diff / commit log.
- **Version** ← `old → new` from step P2. When Phase 1 was skipped, show a bump only if the branch diff already changed
  the version file; otherwise omit the section. Never bump the version in Phase 2.
- **Environment variables** ← the env-var list from step P1 (or "None"). When Phase 1 was skipped, scan the branch diff
  read-only and list new env vars (or "None") — do **not** propagate them to project files here.

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

### 6. Final output

Print the summary defined in [`references/final-output.md`](references/final-output.md) (PR/MR URL + Jira link).
`<site>` is your Jira site host.

## Edge cases

See [`references/edge-cases.md`](references/edge-cases.md) for the full failure-mode table (auth/resource failures,
reviewer-resolution problems, push/PR-MR/Jira errors, existing-PR/MR and cancel handling).

## Notes

- **Phase 1 mutates local files only** (env-example / container compose / README, version file, changelog, `CLAUDE.md`)
  — it never pushes and never opens a PR/MR. `prep-only` stops there.
- **Phase 2 never pushes to `main` / `master`** or any protected branch directly. Never amends commits, force-pushes, or
  skips hooks.
- **Language-agnostic** — treat the env-example file, container compose file, version file, and changelog as roles to
  map onto your stack, not fixed filenames.
- **Host-agnostic** — wire your git host's CLI/MCP in the Host integration section.
- PR/MR title/description conventions are owned by `/common:git-pr`; this skill defers to it and never re-defines them.
- Status transitions are out of scope; use `/common:jira-update` if you also want to move the ticket.
- Use `/common:git-commit` to commit the files Phase 1 changes on the current branch.
