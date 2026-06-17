# Muxy Workflow

The vocabulary for the Muxy + git-worktree development workflow this repo configures (layouts, the worktree lifecycle, project/workspace organization). Glossary only — mechanics live in `docs/adr/`.

## Language

**Project**:
A directory plus Muxy metadata (tabs, splits, worktrees, last-used IDE), registered in Muxy. Registered automatically on clone via `gh.fish`.
_Avoid_: repo (a Project is a Muxy concept and need not be a git repo).

**Workspace**:
A named filter over the Project sidebar. Exactly two exist: `Personal` and `MLB`. Membership is assigned by hand; it moves nothing on disk.
_Avoid_: group, folder, layout.

**Worktree**:
A git worktree attached to a Project, each with its own tabs, splits, and Muxy-persisted state. The primary Worktree is the Project root; additional ones are siblings named `repo.branch`.
_Avoid_: branch checkout, clone.

**Layout**:
A declarative `.muxy/layouts/*.yaml` tree of Panes/Tabs applied to a Worktree on demand via the picker. The canonical set is `agent`, `dev`, `infra`.
_Avoid_: workspace, template, profile.

**Pane**:
A split region of a Worktree window holding a stack of Tabs (one visible at a time). Panes nest as a binary tree of horizontal (columns) / vertical (rows) splits.

**Tab**:
One terminal/command within a Pane's stack. Background Tabs keep running while hidden, so long-lived processes (dev server, watch) live as Tabs.

**Band**:
The full-width bottom Pane in our Layouts, holding the `shell`/`editor`/`watch` Tab stack beneath the full-width agent Pane.
_Avoid_: footer, drawer.

**Agent**:
An AI CLI (e.g. Claude Code) running in a Pane. One Agent per Worktree — parallel Agents get separate Worktrees, never shared.
_Avoid_: assistant (Muxy's "AI Assistant" is only commit/PR text generation, a different thing).
