# Umbrella (multi-PR/MR) Description Template

Use for the body of a sub-PR/MR opened under **delivery model B (umbrella / multi-PR/MR split)** in develop Step 8b.

It is a copy of the `/dev:open-pr` PR/MR body format — the team-agreed standard — adapted for a PR/MR series: the same
sections in the same order, plus one umbrella-only **Series context** section. Model A single PRs/MRs do **not** use
this file; they delegate to `/dev:open-pr` directly.

develop opens Model B PRs/MRs itself, because the umbrella / stacked base refs don't fit `/dev:open-pr`. As a result it
does **not** request a reviewer or set the Jira review field on sub-PRs/MRs — that's intentionally out of scope for the
umbrella path.

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

One paragraph: what **this** PR/MR delivers and why. Seed it from the `/dev:open-pr prep-only` change summary (Step 8b).
For preparation-only PRs/MRs, lead with "No user-visible change — internal `<X>`."

### 2. Series context

Where this PR/MR sits in the umbrella series. Two parts.

**Status table** — every PR/MR in the series, the current one marked:

| PR/MR        | Branch     | Status            | Content  |
| ------------ | ---------- | ----------------- | -------- |
| I (Setup)    | `-setup`   | Merged: `<url>`   | one line |
| II (Helpers) | `-helpers` | **this PR/MR**    | one line |
| III (...)    | `-cleanup` | pending           | one line |

**Branching diagram** — ASCII, annotate the current PR/MR with `← THIS PR/MR`:

```
feature/<TICKET>-setup    ──merged──►   feature/<TICKET>     (PR/MR I, merged)
feature/<TICKET>-helpers  ──to-merge──► feature/<TICKET>     (← THIS PR/MR)
                          ──final────►  <default-branch>     (umbrella merge, at the end)
```

**Stacked-base note (only when stacked).** If the base is the preceding PR/MR's head branch (because it isn't merged
yet), say so and add the retarget reminder:

> "Base is `feature/<TICKET>-<prev>` (PR/MR `<N-1>` head) while it's unmerged, so the diff shows only this PR/MR's
> commits. After PR/MR `<N-1>` merges, retarget this PR/MR's base at `feature/<TICKET>` (the umbrella)."

Omit the note when the PR/MR is rooted directly on the umbrella (the default after the preceding PR/MR merged).

### 3. Version

`<old> → <new>` from the `/dev:open-pr prep-only` checklist run (Step 8b). Omit the section entirely if there was no
bump.

### 4. Environment variables

The new env-var list from the `/dev:open-pr prep-only` checklist run (Step 8b), or "None". They are already propagated to the env-example file /
container compose file / README by that step — this section just reports them.

### 5. Jira

A link to the ticket on your Jira site, e.g. `[<TICKET>](https://<your-jira-site>/browse/<TICKET>)`.

### 6. Test plan

Concrete numbered steps, each with the exact command / click and the expected outcome. Cover at minimum:

1. Build / typecheck — the exact commands (install deps, build, …), "must pass with 0 errors".
2. Setup notes — env entries, network/VPN access, dev login flow, if any.
3. Manual flow — URLs to open / things to click and what to verify.
4. Regression check — sibling features sharing the changed code path must be verified untouched.

---

## Discovering previous PRs/MRs in the series

Before filling Series context, enumerate the existing PRs/MRs under the umbrella ticket. Use whatever your git host
exposes — its CLI's "list PRs/MRs" command filtered by the ticket key, or its web UI search. Capture each one's number,
title, base branch, head branch, URL, and state.

Match by title (`<TICKET> PR/MR I:` …) or by head branch (`feature/<TICKET>-<step>`); capture URL + state + a one-line
summary. If nothing matches, ask the user for the prior PR/MR URLs — do not invent them. If they can't supply them,
note "(previous PRs/MRs not listed — links missing)" so the reviewer notices.

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
