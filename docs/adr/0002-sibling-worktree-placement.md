# Sibling worktree placement, `repo.branch`

Worktrees live as siblings of the repo, named `repo.branch` with branch slashes flattened to dashes (e.g. `~/Code/github.com/you/app.feat-x`). This keeps every Worktree inside the `~/Code/{host}/` path that `git config`'s `includeIf` keys on, so per-host identity and 1Password SSH signing keep applying — which is essential for the corporate hosts `emu.github.com` and `github.mlbam.net`.

## Considered Options

- **Central worktree dir** (e.g. `~/worktrees/app-feat-x`) — rejected: falls outside the `includeIf "gitdir/i:~/Code/{host}/"` globs, so corporate commits would silently use the wrong identity and signing key.
- **Nested** (`repo/.worktrees/feat-x`) — rejected: stays inside the `includeIf` path but risks tree-walking tools (search, watchers) and needs per-repo ignoring.

## Consequences

- Worktrees must always be created under `~/Code/{host}/...`; worktrunk's path template is configured accordingly.
- The dot separator means branch names with slashes are flattened (`feat/x` → `app.feat-x`).
