# Umbrella (multi-PR/MR) Description Template

Use for the body of a sub-PR/MR opened under **delivery model C (umbrella / stacked multi-PR/MR split)** in develop
Step 6b.

It is a copy of the `/dev:open-pr` PR/MR body format — the team-agreed standard — adapted for a PR/MR series: the same
sections in the same order, plus one umbrella-only **Series context** section. Models A and B (single PR/MR) do **not**
use this file; they delegate to `/dev:open-pr` directly (one merged call: checklist + push + open).

develop opens Model C sub-PR/MRs itself, because the umbrella / stacked base refs don't fit `/dev:open-pr`'s
single-base, single-ticket open. As a result it does **not** request a reviewer or set the optional Jira review field
on sub-PR/MRs — that's intentionally out of scope for the umbrella path.

Host-agnostic and language-agnostic: "PR/MR" is the generic pull/merge request, "default branch" is whatever the repo
uses (`main` / `master` / …), and every git-host step is "your git host's CLI or web UI". Branch/base conventions for
Model C live in `/dev:implement-from-analysis`'s `references/conventions.md` (umbrella `feature/<TICKET>`, sub-branches
`feature/<TICKET>-<step>`, stacked retargeting) — this template does not duplicate them.

---

## Language

**Default: English** for the body + title. Ask only on a concrete signal otherwise (the user said so, the source is in
another language, or a prior PR/MR in the series used one). Keep the section names below.

---

## Title

`<TICKET> PR/MR <N>: <short summary>` — e.g. `PROJ-408 PR III: aggregated sorting + customer overview`. Under ~80
chars; let the body carry the detail.

---

## Body sections (in order)

### 1. Summary

One paragraph: what **this** sub-PR/MR delivers and why. Seed it from the `/dev:open-pr prep-only` change summary
(run in develop Step 6b). For preparation-only sub-PR/MRs, lead with "No user-visible change — internal `<X>`."

### 2. Series context

Where this sub-PR/MR sits in the umbrella series. Two parts.

**Status table** — every sub-PR/MR in the series, the current one marked:

| PR/MR        | Branch     | Status            | Content  |
| ------------ | ---------- | ----------------- | -------- |
| I (Setup)    | `-setup`   | Merged: `<url>`   | one line |
| II (Helpers) | `-helpers` | **this PR/MR**    | one line |
| III (...)    | `-cleanup` | pending           | one line |

**Branching diagram** — ASCII, annotate the current sub-PR/MR with `← THIS PR/MR`:

```
feature/<TICKET>-setup    ──merged──►   feature/<TICKET>     (PR/MR I, merged)
feature/<TICKET>-helpers  ──to-merge──► feature/<TICKET>     (← THIS PR/MR)
                          ──final────►  <default-branch>     (umbrella merge, at the end)
```

**Stacked-base note (only when stacked).** If the base is the preceding sub-PR/MR's head branch (because it isn't
merged yet), say so and add the retarget reminder:

> "Base is `feature/<TICKET>-<prev>` (sub-PR/MR `<N-1>` head) while it's unmerged, so the diff shows only this
> sub-PR/MR's commits. After sub-PR/MR `<N-1>` merges, retarget this one's base at `feature/<TICKET>` (the umbrella)
> via your git host's CLI or web UI."

Omit the note when the sub-PR/MR is rooted directly on the umbrella (the default after the preceding one merged).

### 3. Version

`<old> → <new>` from the `/dev:open-pr prep-only` checklist run (develop Step 6b). Omit the section entirely if there
was no bump.

### 4. Environment variables

The new env-var list from the `/dev:open-pr prep-only` checklist run (develop Step 6b), or "None". They are already
propagated to the env-example file / container compose file / README by that step — this section just reports them.

### 5. Jira

A link to the ticket on your Jira site, e.g. `[<TICKET>](https://<your-jira-site>/browse/<TICKET>)`.

### 6. Test plan

Concrete numbered steps, each with the exact command / click and the expected outcome. Cover at minimum:

1. Build / typecheck — the exact commands (install deps, build, …), "must pass with 0 errors".
2. Setup notes — env entries, network/VPN access, dev login flow, if any.
3. Manual flow — URLs to open / things to click and what to verify.
4. Regression check — sibling features sharing the changed code path must be verified untouched.

---

## Base ref selection (which branch this sub-PR/MR targets)

- **Preceding sub-PR/MR merged** → base = `feature/<TICKET>` (the umbrella). This is the default.
- **Preceding sub-PR/MR still open (stacked)** → base = `feature/<TICKET>-<prev-step>` (the head branch of the
  preceding open sub-PR/MR), so the diff stays minimal. Add the stacked-base note (above) to the body, and after the
  preceding one merges, retarget this base at the umbrella.

---

## Discovering previous PRs/MRs in the series

Before filling Series context, enumerate the existing PR/MRs under the umbrella ticket. Use whatever your git host
exposes — its CLI's "list PR/MRs" command filtered by the ticket key, or its web UI search. Capture each one's number,
title, base branch, head branch, URL, and state.

Match by title (`<TICKET> PR/MR I:` …) or by head branch (`feature/<TICKET>-<step>`); capture URL + state + a one-line
summary. If nothing matches, ask the user for the prior PR/MR URLs — do not invent them. If they can't supply them,
note "(previous PR/MRs not listed — links missing)" so the reviewer notices.

---

## Passing the body to your git host

When the host's CLI accepts the PR/MR body on the command line, pass it via a quoted heredoc so tables / code fences /
diagrams survive intact (the `'EOF'` quoting prevents the shell from expanding `$`, backticks, etc.):

```bash
git push -u origin <head-ref>
<your-host-cli> <create-pr-or-mr-command> \
  --base <umbrella-or-stacked-base> \
  --head <head-ref> \
  --title "<TICKET> PR/MR <N>: <summary>" \
  --body "$(cat <<'EOF'
## Summary
...
EOF
)"
```

The exact subcommand and flag names depend on your git host's CLI — the client wires that here. The web UI is an
equally valid path; the heredoc only matters when the body goes through a shell.

---

## Section checklist (before opening)

1. [ ] Summary
2. [ ] Series context — status table + branching diagram (+ stacked-base note if stacked)
3. [ ] Version (or omitted if no bump)
4. [ ] Environment variables (or "None")
5. [ ] Jira link
6. [ ] Test plan — numbered, concrete commands, expected outcomes
