# Worktrunk owns the worktree lifecycle

Worktree creation, sibling pathing, teardown, and per-worktree environment setup are owned by [worktrunk](https://worktrunk.dev) (`wt`) — not a hand-rolled fish function and not Muxy's built-in `create-worktree`. Worktrunk's default path template already emits the sibling `repo.branch` form we want, it installs via Homebrew (so it rides in the Brewfile and stays reproducible), and it is purpose-built for parallel-agent workflows, giving us lifecycle hooks for free instead of code to maintain. Muxy stays the UI / Pane layer and learns about Worktrees through `muxy refresh-worktrees`.

## Considered Options

- **Custom `wt` fish function** — rejected: it would re-implement worktrunk's path template, slash-flattening, and hooks by hand, and worktrunk's own binary is `wt`, so the names would collide.
- **Muxy `create-worktree`** — rejected: couples creation to the GUI, with no path template, hooks, or merge/teardown flow.

## Consequences

- A worktrunk post-start hook is the single integration point: it preps the environment, symlinks Layouts, then calls `muxy refresh-worktrees` + `muxy switch-worktree`.
- Muxy's "auto-expand worktrees on project switch" is enabled as a safety net so Worktrees made outside worktrunk still surface.
