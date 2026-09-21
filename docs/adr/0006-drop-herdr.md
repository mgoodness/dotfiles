# Drop herdr; worktrunk stands alone

Herdr — the terminal workspace/pane manager this repo layered on top of worktrunk (ADR-0001) — is removed. Worktrunk continues to own worktree creation, sibling pathing, and teardown entirely on its own; there is no longer any automatic "open a UI container for this worktree" step after `wt switch --create`.

<!-- TODO(maintainer): replace this paragraph with the actual reason herdr is being dropped (reliability, maintenance cost, consolidating tools, etc.) before merging. Left generic because the agent drafting this PR wasn't told the reason. -->

## Consequences

- `dot_config/worktrunk/config.toml`'s `post-start` hook (previously `herdr worktree open ...`) is gone; a new worktree only gets `pre-start` env prep (mise/direnv) — no window or pane is opened for you automatically anymore.
- `CONTEXT.md`'s herdr vocabulary (Workspace, Workspace label, Tab, Pane, Agent) is removed. "Worktree" reverts to its plain git meaning; there's no herdr container above it to disambiguate from.
- ADR-0001 and ADR-0004 are marked superseded by this record: both described herdr-specific mechanics (the post-start integration point; `herdr agent prompt`/worktrunk-plugin keybinds) that no longer apply. Neither ADR's _other_ content — worktrunk owning the lifecycle (0001), one agent per worktree (0004) — is reversed by this decision.
- The `spin-up-worktrees` homegrown skill is deleted outright: its entire mechanism was opening (and later verifying/closing) a nested herdr workspace per worktree, so nothing salvageable remains once herdr is gone. `cleanup-branch`'s herdr-workspace teardown step is dropped too, which removes a safety check it relied on (confirming no live agent was still running in a worktree's directory before deleting it) — there is currently no replacement for that check.
- This ADR only covers what this repo's chezmoi config does. It does not itself uninstall herdr's binary, launchd service, or the externally-installed `herdrdev/herdr` agent skill from any machine that already has them — that's separate manual cleanup on each machine.
