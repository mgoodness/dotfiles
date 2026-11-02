---
name: cleanup-branch
description: Clean up a branch and everything around it — its worktree, its Rex tab, its remote ref, and its local branch. Use when the user wants to clean up after a PR is merged, or mentions "delete worktree" or "delete branch".
---

# Cleanup Branch

Remove a branch once its PR is merged: its worktree, its Rex tab, the local branch, and the remote ref.

## Workflow

### 1. Find the branch and its PR

Run `git rev-parse --show-toplevel` to get the current worktree path.
Run `git worktree list` to find all worktrees; the **main worktree** is the one listed first, since it owns `.git`.

Resolve the repo you push to, once, and name it on every `gh` call below:

```sh
repo=$(git remote get-url origin | sed -E 's#^git@[^:]+:##; s#^https?://[^/]+/##; s#\.git$##')
```

A bare `gh` call takes its repo from the tracked remote's `gh-resolved` entry, which `gh repo set-default <upstream>` points at the repo you _don't_ push to — so it quietly reads upstream's PRs instead of yours.

If the current worktree IS the main worktree, enumerate all non-main worktrees and look up their associated PRs. For each non-main worktree, prefer running from within that worktree's directory when possible:

```sh
gh pr view --repo "$repo" --json number,state,mergedAt,title,headRefName
```

If the worktree path is outside the project root (not usable as a `cd` target), fall back to querying by branch name from the main worktree — include `--state all` to catch merged PRs:

```sh
gh pr list --repo "$repo" --head <branch> --state all --json number,state,mergedAt,title,headRefName
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
gh pr view --repo "$repo" --json number,state,mergedAt,title,headRefName
```

- If `state` is not `"MERGED"`, abort: "PR #N is not merged (state: STATE). Aborting."
- Record `headRefName` (branch) and `number` for later steps.

### 4. Switch to the main worktree

All remaining steps must run from the main worktree. Use the main worktree path as the `cd` parameter for every subsequent terminal call.

Verify you are in the right place:

```sh
git rev-parse --abbrev-ref HEAD
```

This should print the branch the main worktree has checked out (e.g. `main`).

### 5. Pull the main worktree

From the main worktree path, fast-forward the branch it has checked out, from the remote it tracks:

```sh
git pull --ff-only
```

Upstream syncing stays out of cleanup: upstream's branch need not share your fork's name — here `master` against `main` — so pulling `upstream/<branch>` either misses or crosses lineages.

### 6. Confirm before deleting

Show the user exactly what will be removed:

- Branch: `<headRefName>`
- Worktree path: `<path>` (or "none")
- Rex tab: the tab labelled `<branch>` in the repo's session, or failing that the tab with a pane running at `<path>` (or "none")

Ask: "Delete branch `<branch>`[and remove worktree at `<path>`]? (y/N)"

Abort if the user declines.

### 7. Close its Rex tab

Close the worktree's tab before the directory goes away. The Rex layout is in the global `AGENTS.md`; the `rex` skill has the CLI mechanics. Closing a tab closes all its panes with no `busy` refusal, so the checks below are yours to run. `$repo` is the session's label, the repo's name.

Find the tab by its label. If none matches (a hand-made or renamed tab), fall back to the tab holding a pane whose foreground process runs under the worktree path (`rex block call -b <block> process`, `.foreground.cwd`, compared against `pwd -P` of the worktree; the `pwd` method is empty for programs launched directly).

```sh
tab=$(rex session inspect "$repo" --json | jq -r --arg b "<branch>" '.windows[] | select(.label == $b) | .window_id')
for b in $(rex block ls -s "$repo" --json | jq -r --arg w "$tab" '.blocks[] | select(.window_id == $w) | .block_id'); do
  echo "$b $(rex block call -s "$repo" -b "$b" program_status | jq -c '[.records[].state]')"
done
```

Then, in order:

1. **A pane is `working` or `blocked`** → the agent is mid-turn or waiting on the user. Surface that and stop; do not close. A pane running the agent (`process` → `.foreground.argv0` is `pi`) that reports no records at all is unknown, not idle: `rex capture -s "$repo" -b <block> --trim | tail` and ask the user if it isn't plainly at its prompt.
2. **`$REX_BLOCK` is one of the tab's panes** → this agent lives in the tab being closed. Skip the close, tell the user to close it themselves, and carry on with the remaining steps.
3. **Keep the `main` tab**, the trunk worktree's.
4. Otherwise close it: `rex window close -s "$repo" "$tab"`.

An agent resting at its prompt (`idle`, or `done` once its turn finished) is safe to close without a graceful quit. Closing the last tab leaves the session alive and empty.

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

The branch is gone locally and from `origin`, its worktree no longer appears in `git worktree list`, and no tab in the repo's Rex session is labelled with it or has a pane running at its path.
