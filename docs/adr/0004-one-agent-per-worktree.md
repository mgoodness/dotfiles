# One agent per worktree

Parallel AI Agents each get their own Worktree (and branch); we never run multiple _editing_ Agents as separate Panes on one shared working tree. A shared working tree means concurrent Agents overwrite each other's uncommitted edits, defeating the isolation that worktrees exist to provide. Worktrunk is built for exactly this fan-out (`wt switch --create taskN`), and Herdr's worktrunk plugin binds `prefix+shift+g` / `prefix+shift+c` to switch or create a Worktree from the default or current branch.

## Consequences

- Read-only / exploratory fan-out (e.g. prompting several Panes individually via `herdr agent prompt`) is the only sanctioned multi-Agent-on-one-Worktree case — Herdr has no single-broadcast primitive like Muxy's Rich Input `⌘I`.
- Watching N Agents is sequential — you switch Worktrees to check each, rather than seeing them side by side.
