# Worktrunk owns the worktree lifecycle

Worktree creation, sibling pathing, teardown, and per-worktree environment setup are owned by [worktrunk](https://worktrunk.dev) (`wt`) — not a hand-rolled fish function and not Herdr's built-in `worktree create`. Worktrunk's default path template already emits the sibling `repo.branch` form we want, it installs via Homebrew (so it rides in the Brewfile and stays reproducible), and it is purpose-built for parallel-agent workflows, giving us lifecycle hooks for free instead of code to maintain. Herdr stays the UI / Pane layer: a worktrunk post-start hook calls `herdr worktree open --path ... --focus` to nest the new worktree under the right Herdr workspace.

## Considered Options

- **Custom `wt` fish function** — rejected: it would re-implement worktrunk's path template, slash-flattening, and hooks by hand, and worktrunk's own binary is `wt`, so the names would collide.
- **Herdr's built-in `worktree create`** — rejected: couples creation to the GUI, with no path template, hooks, or merge/teardown flow. (The herdr-worktrunk plugin's default `prefix+shift+g` binding is overridden in `dot_config/herdr/config.toml` for the same reason — it now opens worktrunk's switch/create picker instead.)

## Consequences

- A worktrunk post-start hook is the single integration point: it preps the environment (`mise`/`direnv`), pulls in the agent-context branch's files if the repo has one, then calls `herdr worktree open --path "{{ worktree_path }}" --label "{{ branch }}" --focus`.
- Herdr has no equivalent of Muxy's "auto-expand worktrees on project switch" safety net — a Worktree made outside worktrunk won't automatically surface in Herdr and needs `herdr worktree open` run for it explicitly.
