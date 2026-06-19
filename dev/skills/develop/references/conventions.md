# Conventions — develop

Branch naming, worktree paths, PR/MR base refs, and merge direction by delivery model.

## Model A — single PR/MR via worktree

| Item | Convention | Example |
|------|-----------|---------|
| Branch name | `<TICKET>-<short-name>` | `PROJ-408-storage-migration` |
| Worktree location | `.worktrees/<TICKET>-<short-name>/` | `.worktrees/PROJ-408-storage-migration/` |
| PR/MR base | default branch (`main`, `master`, `stage`) | `main` |
| Merge direction | branch → default branch | one PR/MR, one merge |

Set up the worktree with native `git worktree`, or the `superpowers` plugin's `using-git-worktrees` skill if installed.

## Model B — multi-PR/MR split

| Item | Convention | Example |
|------|-----------|---------|
| Umbrella branch | `feature/<TICKET>` | `feature/PROJ-408` |
| Sub-branches | `feature/<TICKET>-<step-name>` | `feature/PROJ-408-setup`, `feature/PROJ-408-helpers`, `feature/PROJ-408-aggregated`, `feature/PROJ-408-cleanup` |
| PR/MR base (preceding PR/MR merged) | `feature/<TICKET>` (umbrella) | base = `feature/PROJ-408` |
| PR/MR base (preceding PR/MR still open) | preceding sub-branch (stacked) | base = `feature/PROJ-408-helpers` |
| Final umbrella merge | `feature/<TICKET>` → default branch | once all sub-PRs/MRs are merged into the umbrella |

**No worktree** in model B — sub-branches sit directly off the umbrella.

### First-time umbrella setup

```bash
git checkout <default-branch>
git pull
git checkout -b feature/<TICKET>
git push -u origin feature/<TICKET>   # umbrella must exist on the remote so the sub-PR/MR base resolves
```

### Creating each sub-branch

```bash
git checkout feature/<TICKET>
git pull
git checkout -b feature/<TICKET>-<step-name>
```

### Stacked PR/MR base retargeting

If a sub-PR/MR is opened while the preceding sub-PR/MR is still open, its base points at the preceding sub-branch (so the diff stays minimal). After the preceding sub-PR/MR merges, retarget the open PR/MR's base at the umbrella (`feature/<TICKET>`).

Most git hosts let you change a PR/MR's target branch after it is opened, from the web UI or the host's CLI. No rebase is needed — the host recomputes the diff against the new base automatically.

## After any branch setup

Run the test suite (or `build` + `lint` if there's no test runner) to confirm a clean baseline before implementation starts.
