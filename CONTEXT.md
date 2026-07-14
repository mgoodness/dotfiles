# cmux Workflow

The vocabulary for the cmux + git-worktree development workflow this repo configures (the worktree lifecycle, workspace-group organization). Glossary only — mechanics live in `docs/adr/`.

## Language

**Workspace**:
cmux's tab-like entity for one worktree — carries its own cwd, panes, and surfaces. Opened automatically by `gh.fish` (fresh clone) and the worktrunk `post-start` hook (new worktree).
_Avoid_: project, worktree (the git object is still a worktree; the cmux tab representing it is a Workspace), tab (that's one level deeper — see Surface).

**Workspace group**:
A named grouping of Workspaces in the cmux sidebar (`cmux workspace-group`). Exactly two exist: `Personal` and `MLB`. Membership is assigned by hand; it moves nothing on disk.
_Avoid_: workspace (see above — cmux overloads this word for two different things), group, folder, layout.

**Worktree**:
A git worktree attached to a Workspace. The primary Worktree is the repo root; additional ones are siblings named `repo.branch`.
_Avoid_: branch checkout, clone.

**Pane**:
A split region of a Workspace window holding a stack of Surfaces (one visible at a time). Panes nest as a binary tree of horizontal (columns) / vertical (rows) splits.

**Surface**:
One terminal/browser/agent-session within a Pane's stack. Background Surfaces keep running while hidden, so long-lived processes (dev server, watch) live as Surfaces.
_Avoid_: tab (that's the UI chrome for a Surface, not the concept), pane (one level up).

**Band**:
The full-width bottom Pane holding the `shell`/`watch` Surface stack beneath the upper working Pane. The editor is a dedicated Surface in the upper Pane (alongside the Agent), never in the Band. Nothing provisions this automatically — the upper/lower ~80/20 sizing is a one-time manual drag per Workspace.
_Avoid_: footer, drawer.

**Agent**:
An AI CLI (e.g. Claude Code) running in a Surface. One Agent per Workspace — parallel Agents get separate Workspaces (one per worktree), never shared.
_Avoid_: assistant.
