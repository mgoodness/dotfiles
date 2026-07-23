# herdr Workflow

The vocabulary for the herdr + git-worktree development workflow this repo configures (the worktree lifecycle, workspace organization). Glossary only — mechanics live in `docs/adr/`.

## Language

**Workspace**:
herdr's top-level entity for one worktree (or a fresh clone) — carries its own cwd, tabs, and panes. Opened automatically by `gh.fish` (fresh clone) and the worktrunk `post-start` hook (new worktree). Worktree-backed workspaces nest automatically under any other open workspace on the same repo (matched by `repo_key`, read off the worktree's own git metadata) — no manual grouping step.
_Avoid_: project, worktree (the git object is still a worktree; the herdr entity representing it is a Workspace), tab (that's one level deeper — see Tab).

**Workspace label** (informal):
`Personal` / `MLB` as a naming convention only, not an enforced hierarchy — herdr has no group/folder primitive the way cmux's `workspace-group` was. Organize by eye or by label text; nothing on disk or in herdr's API tracks membership.
_Avoid_: workspace group (that implied CLI-enforced membership; there isn't one).

**Worktree**:
A git worktree attached to a Workspace. The primary Worktree is the repo root; additional ones are siblings named `repo.branch`.
_Avoid_: branch checkout, clone.

**Tab**:
A terminal layout within a Workspace, holding one or more Panes. A new Workspace starts with one Tab and one root Pane.
_Avoid_: window (that's the OS-level Ghostty window, a level above Workspace, not this).

**Pane**:
A single terminal within a Tab — one process, not a stack. Panes split as a binary tree (`herdr pane split --direction right|down`). There's no cmux-style Surface concept here: a Pane can't hold several terminals with only one visible at a time. A second long-lived process (e.g. a watch task) needs its own Pane or Tab.
_Avoid_: surface (cmux-specific term, no herdr equivalent).

**Agent**:
An AI CLI (e.g. Claude Code) running in a Pane, natively tracked by herdr — `agent` and `agent_status` (`idle` / `working` / `blocked` / `done` / `unknown`) are reported directly per Pane, not inferred from screen text. One Agent per Workspace — parallel Agents get separate Workspaces (one per worktree), never shared.
_Avoid_: assistant.
