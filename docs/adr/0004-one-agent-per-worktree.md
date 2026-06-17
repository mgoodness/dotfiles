# One agent per worktree

Parallel AI Agents each get their own Worktree (and branch); we never run multiple _editing_ Agents as separate Panes on one shared working tree. A shared working tree means concurrent Agents overwrite each other's uncommitted edits, defeating the isolation that worktrees exist to provide. Worktrunk is built for exactly this fan-out (`wt switch --create taskN`), and Muxy's `⌘⇧O` rotates between Worktrees.

## Consequences

- Read-only / exploratory fan-out (e.g. broadcasting one prompt to several Panes via Muxy Rich Input `⌘I`) is the only sanctioned multi-Agent-on-one-Worktree case.
- Watching N Agents is sequential — you switch Worktrees to check each, rather than seeing them side by side.
