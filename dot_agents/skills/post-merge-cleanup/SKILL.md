---
name: post-merge-cleanup
description: Clean up a merged PR's branch and worktree. Verifies the merge via gh CLI, pulls the repo default branch, then deletes the merged branch and worktree with user confirmation. Use when user wants to clean up after a PR is merged, mentions "cleanup after merge", "delete worktree", "PR is merged clean up", or says "clean up this branch/worktree".
---

# Post-Merge Cleanup

## Workflow

### 1. Detect context

Run `git rev-parse --show-toplevel` to get the current worktree path.
Run `git worktree list` to find all worktrees.

Find the default branch:

```sh
gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
```

Identify the **main worktree** as the one whose branch matches the default branch.

If the current worktree IS the main worktree, enumerate all non-main worktrees and look up their associated PRs. For each non-main worktree, prefer running from within that worktree's directory when possible:

```sh
gh pr view --json number,state,mergedAt,title,headRefName
```

If the worktree path is outside the project root (not usable as a `cd` target), fall back to querying by branch name from the main worktree — include `--state all` to catch merged PRs:

```sh
gh pr list --head <branch> --state all --json number,state,mergedAt,title,headRefName
```

Present a table of results to the user:

| #   | PR  | Title         | State  | Worktree path     |
| --- | --- | ------------- | ------ | ----------------- |
| 1   | #42 | Fix login bug | MERGED | /path/to/worktree |

Include all PRs found — merged, open, and those with no associated PR (show "—" for PR and title). Then ask: "Which worktree should be cleaned up? (enter row number or PR number)" Resolve the selection to a `headRefName` and worktree path, then continue from step 2.

### 2. Check for uncommitted changes

Run `git status --porcelain`. If output is non-empty, warn and abort:

> "Uncommitted changes detected in this worktree. Stash or commit them before cleanup."

### 3. Verify the merge

Run:

```sh
gh pr view --json number,state,mergedAt,title,headRefName
```

- If `state` is not `"MERGED"`, abort: "PR #N is not merged (state: STATE). Aborting."
- Record `headRefName` (branch) and `number` for later steps.

### 4. Switch to the main worktree

All remaining steps must run from the main worktree. Use the main worktree path as the `cd` parameter for every subsequent terminal call.

Verify you are in the right place:

```sh
git rev-parse --abbrev-ref HEAD
```

This should print the default branch name (e.g. `main`).

### 5. Pull the main worktree

From the main worktree path, check whether an `upstream` remote exists:

```sh
git remote | grep -q upstream && echo yes || echo no
```

If `upstream` exists, pull from it explicitly:

```sh
git pull upstream <default-branch>
```

Otherwise:

```sh
git pull
```

### 6. Confirm before deleting

Show the user exactly what will be removed:

- Branch: `<headRefName>`
- Worktree path: `<path>`

Ask: "Delete branch `<branch>` and remove worktree at `<path>`? (y/N)"

Abort if the user declines.

### 7. Remove the worktree

From the main worktree path:

```sh
git worktree remove <path>
```

Fallback — if this fails:

- **Untracked/modified files:** offer "Remove failed. Run with --force?", then retry with `git worktree remove --force <path>`.
- **Submodules** (`fatal: working trees containing submodules cannot be moved or removed`): `git worktree remove` cannot handle these. Instead, manually delete the directory and let prune clean up the ref:
  ```sh
  rm -rf <path>
  ```
  Then continue — the stale worktree ref will be cleared in step 9.

### 8. Prune stale worktree refs

From the main worktree path:

```sh
git worktree prune
```

Do this **before** deleting the branch. When a worktree was removed via `rm -rf` (submodule case), git still considers the branch "in use" until the stale ref is pruned, causing `git branch -d` to fail.

### 9. Delete the branch

From the main worktree path:

```sh
git branch -d <branch>
```

If `-d` fails (common after squash-merge), offer: "Branch not fully merged locally. Delete with -D?"

### 10. Confirm completion

Report: "Done. Branch `<branch>` deleted, worktree at `<path>` removed, and stale refs pruned."
