# Conventions — delivery models

Branch naming, worktree paths, PR/MR base refs, and merge direction by delivery model. Host-agnostic and
language-agnostic: "default branch" means whatever the repo uses (`main` / `master` / …), "PR/MR" is the generic
term for a pull/merge request, and every git-host step is "your git host's CLI or web UI".

## Model A — single PR/MR via worktree

| Item | Convention | Example |
|------|-----------|---------|
| Branch name | `<TICKET>-<short-name>` | `PROJ-408-storage-migration` |
| Worktree location | `.worktrees/<TICKET>-<short-name>/` | `.worktrees/PROJ-408-storage-migration/` |
| PR/MR base | default branch | the repo's default branch |
| Merge direction | branch → default branch | one PR/MR, one merge |

Create the worktree under `.worktrees/<branch>/` with native git (`git worktree add`), or via
`superpowers:using-git-worktrees` if that plugin is installed.

## Model B — single PR/MR on current branch (no worktree)

Same single-PR/MR outcome as Model A but **without** the worktree isolation — the implementation happens directly
in the current workspace. Use when you want a single PR/MR but don't need (or want) a separate worktree directory.

| Item | Convention | Example |
|------|-----------|---------|
| Branch name | `<TICKET>-<short-name>` | `PROJ-408-storage-migration` |
| Workspace | current workspace (no worktree dir) | — |
| PR/MR base | default branch | the repo's default branch |
| Merge direction | branch → default branch | one PR/MR, one merge |

### Preconditions

- **Clean working tree required.** If `git status` shows uncommitted changes, stop and ask the user to commit /
  stash them before proceeding. The implementation may switch branches in the user's current workspace, so any
  dirty state could be lost or carried into the wrong branch.
- **If the user is on the default branch**, suggest creating a feature branch first
  (`git checkout -b <TICKET>-<short-name>`). Do not implement directly on the default branch.
- **If the user is already on a feature branch** that matches the ticket, reuse it. Otherwise create
  `<TICKET>-<short-name>` from the default branch.

### Trade-offs vs Model A

- **+** No worktree dir to clean up afterwards; everything stays in the user's main workspace.
- **+** No worktree setup overhead.
- **−** No isolation from existing in-progress work — the workspace must be clean.
- **−** Switching back to other branches mid-implementation requires committing or stashing the in-flight work.

## Model C — umbrella + stacked sub-branches (multi-PR/MR)

| Item | Convention | Example |
|------|-----------|---------|
| Umbrella branch | `feature/<TICKET>` | `feature/PROJ-408` |
| Sub-branches | `feature/<TICKET>-<step-name>` | `feature/PROJ-408-setup`, `feature/PROJ-408-helpers`, `feature/PROJ-408-cleanup` |
| PR/MR base (preceding PR/MR merged) | `feature/<TICKET>` (umbrella) | base = `feature/PROJ-408` |
| PR/MR base (preceding PR/MR still open) | preceding sub-branch (stacked) | base = `feature/PROJ-408-helpers` |
| Final umbrella merge | `feature/<TICKET>` → default branch | once all sub-PR/MRs are merged into umbrella |

**No worktree** in Model C — sub-branches sit directly off the umbrella.

### First-time umbrella setup

```bash
git checkout <default-branch>
git pull
git checkout -b feature/<TICKET>
git push -u origin feature/<TICKET>   # umbrella must exist on remote so sub-PR/MR base resolves
```

### Creating each sub-branch

```bash
git checkout feature/<TICKET>
git pull
git checkout -b feature/<TICKET>-<step-name>
```

### Stacked PR/MR base retargeting

If a sub-PR/MR is opened while the preceding sub-PR/MR is still open, its base points at the preceding sub-branch
(so the diff stays minimal). After the preceding sub-PR/MR merges, **retarget the sub-PR/MR's base to the umbrella
via your git host's CLI or web UI**. No rebase is needed — git hosts recompute the diff against the new base
automatically.

## Model D — local-only

No branch conventions specific to this model. The implementation happens on whatever branch the user is currently
on (the default branch is discouraged for non-trivial work — suggest creating a feature branch
`<TICKET>-<short-name>` first). **No push, no PR/MR.** The user pushes manually when ready.

## After any branch setup

Run the test suite (or `build` + `lint` if no test runner) to confirm a **clean baseline** before implementation
starts.
