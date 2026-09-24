---
name: cleanup-branch
description: Clean up a branch and everything around it — its worktree, its Macterm tab, its remote ref, and its local branch. Use when the user wants to clean up after a PR is merged, or mentions "delete worktree" or "delete branch".
---

# Cleanup Branch

Remove a branch once its PR is merged: its worktree, its Macterm tab, the local branch, and the remote ref.

## Workflow

### 1. Find the branch and its PR

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
| 2   | #39 | Old branch    | MERGED | —                 |

Include all PRs found — merged, open, and those with no associated PR (show "—" for PR and title). Show "—" for worktree path when no worktree exists for that branch. Then ask: "Which branch should be cleaned up? (enter row number or PR number)" Resolve the selection to a `headRefName`, worktree path (or none), and continue from step 2.

### 2. Check for uncommitted changes

Run `git status --porcelain`. If output is non-empty, warn:

> "Uncommitted changes detected in this worktree. Stash or commit them, or use `wt remove --force` to discard."

Abort unless the user explicitly chooses `--force`.

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
- Worktree path: `<path>` (or "none")
- Macterm tab: the tab rooted at `<path>` (or "none")

Ask: "Delete branch `<branch>`[and remove worktree at `<path>`]? (y/N)"

Abort if the user declines.

### 7. Close its Macterm tab

Close the worktree's tab before the directory goes away (the `macterm` skill has the CLI mechanics). Find the tab whose pane's `cwd` is the worktree path in `macterm pane list`, then quit its agent and close the tab by id:

```sh
macterm pane key --session <session> ctrl+d   # quit the agent gracefully
macterm tab close <tab-id>
```

The agent is usually still resident, and a close with a running program is refused as `busy`. Quitting first avoids it: pi exits on Ctrl-D (its `app.exit`, when the input is empty), which hands the pane back to its shell. If the input held text, Ctrl-D edits instead, so send Ctrl-C once to clear it, then Ctrl-D. A close that still reports `busy` means the agent is mid-turn — surface that to the user rather than forcing the close, which kills the pane's session.

Close verbs always need an explicit target.

### 8. Remove the worktree and/or branch

**If a worktree exists** — use worktrunk, which handles removal, metadata pruning, and branch deletion in one step:

```sh
wt remove <branch>
```

See the `worktrunk` skill for what `wt remove` actually does (hook timing, background trash-and-prune, merge detection) rather than re-deriving it here.

Fallbacks:

- **Dirty worktree:** `wt remove --force <branch>`
- **Squash-merged / unmerged branch:** `wt remove -D <branch>` (offer this if `wt remove` declines to delete the branch)

**If no worktree exists** — just delete the local branch:

```sh
git branch -d <branch>
```

If `-d` fails (squash-merge), offer: `git branch -D <branch>`.

Alternatively, for bulk cleanup of all merged branches at once:

```sh
gh poi --state merged --dry-run   # preview
gh poi --state merged             # delete
```

Use `gh poi lock <branch>` to protect any branch that should be kept.

### 9. Delete remote branch

Runs for both paths — no-op if GitHub already deleted it:

```sh
git ls-remote --heads origin <branch> | grep -q . && git push origin --delete <branch> || true
```

### 10. Report what was done

Note the branch deleted, and the worktree and tab removed (if applicable).

## Completion criterion

The branch is gone locally and from `origin`, its worktree no longer appears in `git worktree list`, and no Macterm tab is rooted at its path.
