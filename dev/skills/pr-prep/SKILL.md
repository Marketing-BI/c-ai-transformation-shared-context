---
name: pr-prep
argument-hint: "[create-pr] [draft]"
description: |
  Use when the user wants to prepare changes for a pull/merge request after implementation is complete. Runs a
  post-implementation checklist: detect new environment variables and propagate them to the env-example file /
  container compose file / README, bump the project's version file, append a CHANGELOG entry, review CLAUDE.md for
  needed updates, and summarize the changes for a PR/MR description. Host-agnostic and language-agnostic. Optionally
  hands off to /dev:open-pr (regular or draft) when invoked with a create token — open-pr then owns push, PR/MR
  creation, and reviewer assignment. Never pushes or opens a PR/MR unless a create token is in the arguments.

  English triggers: "prep pr", "prep mr", "prepare pr", "prepare mr", "pr prep", "mr prep", "ready for pr",
  "ready for mr", "pre-pr checklist", "/dev:pr-prep", "/dev:pr-prep create-pr", "/dev:pr-prep create-pr draft"

  České spouštěče: "připrav pr", "připrav mr", "příprava pr", "příprava na pr", "předpřipravit pr", "checklist před pr",
  "připrav změny k pull requestu", "/dev:pr-prep", "/dev:pr-prep create-pr", "/dev:pr-prep create-pr draft"

  Do NOT apply when: the user wants to actually push and open the PR/MR (use /dev:open-pr directly), only wants to
  write commit messages (use /common:git-commit), or only wants to move a Jira ticket (use /common:jira-update).
user-invocable: true
allowed-tools:
  Read, Write, Edit, Bash, Glob, Grep, Skill, AskUserQuestion
---

# PR Prep

Post-implementation checklist to prepare changes for a pull/merge request. Run this after implementation is complete,
before push.

This skill is **language- and host-agnostic**. The file names below (env-example file, container compose file, version
file, changelog) are *roles*, not a fixed ecosystem — map each to whatever your project actually uses. It mutates only
local files; it never pushes and never opens a PR/MR unless explicitly told to hand off (see step 6).

## Arguments

- `/dev:pr-prep` — checklist only (default)
- `/dev:pr-prep create-pr` — checklist plus open a PR/MR at the end (hands off to `/dev:open-pr`)
- `/dev:pr-prep create-pr draft` — checklist plus open a PR/MR as draft

Parse arguments loosely: any of `pr`, `mr`, or `create-pr` triggers PR/MR creation; the presence of `draft` opens it
as a draft. Token order does not matter. With **no** create token, this skill stops after step 5 and never pushes or
opens anything.

## Procedure

### 1. Check for new environment variables

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

### 2. Update version

- Read the current version from the project's **version file** (the manifest/descriptor that carries the project
  version — whatever your ecosystem uses).
- Determine the bump type based on the changes, following semantic-versioning intent:
  - **patch**: bug fixes, minor tweaks
  - **minor**: new features, non-breaking additions
  - **major**: breaking changes
- Apply the bump. Prefer the ecosystem's own tooling so any lockfile / companion file stays in sync **without** creating
  a git commit or tag. If no such tool is available, edit the version file directly (and update any lockfile/companion
  file that mirrors the version so they match).

If the project has no version file, note that and skip this step.

### 3. Update changelog

- Add a new version section to the **changelog** (e.g. `CHANGELOG.md`) following the existing format.
- Include the Jira ticket key if available (from the branch name or conversation context).
- Keep entries concise — one bullet per logical change.

If the project keeps no changelog, note that and skip this step.

### 4. Check CLAUDE.md

Review whether the changes affect anything documented in `CLAUDE.md` (and any rule files it references):

- New architectural patterns or modules
- New conventions or constraints
- Changes to existing documented behavior

If updates are needed, apply them. If not, state that no updates are needed.

### 5. Summarize changes

Provide a concise description of all changes made in this session — what was added/changed and why. This should be
suitable for a PR/MR description.

### 6. Hand off to `/dev:open-pr` (only if a create token was passed)

Skip this step entirely if no create token (`create-pr` / `pr` / `mr`) was in the arguments — in that case the skill is
done after step 5 and must not push or open anything.

Push, PR/MR creation, and reviewer assignment are owned by the [`/dev:open-pr`](../open-pr/SKILL.md) skill. This step
just prepares a context block from the artifacts already produced and invokes that skill.

1. Build a context block (paste verbatim into the open-pr invocation):

   ```markdown
   <!-- pr-prep:summary -->
   <step 5 summary>
   <!-- /pr-prep:summary -->

   <!-- pr-prep:env -->
   <list from step 1, or "None">
   <!-- /pr-prep:env -->

   <!-- pr-prep:version -->
   <old> → <new>
   <!-- /pr-prep:version -->
   ```

2. Invoke `/dev:open-pr` via the `Skill` tool. Forward the `draft` token if it was in the original `pr-prep`
   arguments. Pass the context block as part of the skill input so open-pr can substitute the named sections into the
   PR/MR body.

3. `/dev:open-pr` will then:
   - Resolve the Jira ticket key (branch name → recent commits → ask the user).
   - Resolve the reviewer (from its placeholder team mapping, or by asking the user).
   - Push the branch if needed.
   - Confirm the title + body with the user.
   - Open the PR/MR on your git host with the reviewer requested.
   - Optionally set your issue tracker's reviewer/QA field, if your team wires one.
   - Return the PR/MR URL.

Do not open the PR/MR yourself from this skill — `/dev:open-pr` is the single point of truth for PR/MR title/body
assembly and reviewer assignment.

## Important reminders

- **Never pushes, never opens a PR/MR** unless a create token (`create-pr` / `pr` / `mr`) is present. The default run
  is purely local file edits plus a printed summary.
- **Language-agnostic** — treat the env-example file, container compose file, version file, and changelog as roles to
  map onto your stack, not fixed filenames.
- **Host-agnostic** — this skill never talks to a git host. All PR/MR mechanics live in `/dev:open-pr`.
- Use `/common:git-commit` to commit the files this skill changes (env files, version file, changelog, `CLAUDE.md`) on
  the current branch; use `/common:jira-update` if you also want to move the ticket in Jira.
