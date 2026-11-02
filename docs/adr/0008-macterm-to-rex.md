# Replace Macterm with Rex; one session per repo, one tab per worktree

Macterm ([ADR-0006](0006-drop-herdr.md)) is replaced by [Rex](https://www.superlogical.com/rex/docs) (Rex Beta, installed by hand, no Homebrew cask) as the terminal multiplexer worktrunk runs inside. ADR-0006 accepted two gaps for want of tooling: no agent-state tracking and no check that an agent was idle before its worktree was deleted. Rex closes both: pi reports its state over OSC 7501 and `rex block call … program_status` reads it (`idle`, `working`, `blocked`, `done`, `error`).

## Layout

Session = repo, tab = worktree (labelled with its branch; `main` is the trunk), panes inside the tab. A repo's session is labelled with its name, or `<owner>/<repo>` if two hosts share one. The terms, including Rex's CLI naming of a tab as `window`, are defined in `CONTEXT.md`.

## Decisions

- **Agents don't rename sessions.** Rex's agent guide tells agents to label the session after their task. With several agents sharing a repo session that would fight over the label the skills use to find it. `rex.agents.names-sessions` is `false` in `defaults.toml`; pi has no Rex hook, so the rule is also in `dot_pi/agent/AGENTS.md`.
- **Close tabs, never sessions** (`cleanup-branch`): `rex kill` would take down every other worktree's agent. Before closing, `cleanup-branch` reads `program_status` and refuses on `working` or `blocked`, and skips the tab holding its own pane.
- **Rex's agent skill is tool-owned.** `~/.agents/skills/rex` is a stub that reads its guide from the installed CLI, so it is not vendored here. `run_after_23-rex-skill.sh` runs `rex skill setup --agent pi` (idempotent). The `macterm` skill is deleted and removed from machines via `.chezmoiremove`.
- **Notifications come from Rex's program-activity indicators**, driven by pi's native OSC 7501, so the Ghostty-gated `desktop-notify.ts` extension is retired. Rex's own notification settings are a UI choice, not yet declared in `defaults.toml`.
- **Macterm leaves** via the Brewfile (cask dropped) and `run_once_after_17-remove-macterm.sh`.

## Consequences

- `fan-out` needs `rex` reachable and pi ≥ 1.1 (OSC 7501). Readiness is `program_status == idle` rather than scraping the agent's footer.
- Pi's regular TUI mode has had an OSC 133 bug that clears `working` mid-turn (earendil-works/pi#11519); `idle` at startup is unaffected, but a mid-turn `working` read can be empty, so `cleanup-branch` treating "no records" as safe-to-close is only as good as the installed pi.
- `dot_config/ghostty/` and the Catppuccin Ghostty theme external are unused by Rex; kept for standalone Ghostty until removed in a later change.
