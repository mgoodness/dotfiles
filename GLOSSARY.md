# Dotfiles Repo Conventions

Vocabulary for concepts specific to how this repo organizes machine provisioning (chezmoi). Glossary only — mechanics live in `docs/adr/`.

## Language

### Chezmoi Machine Roles

**Chezmoi role**:
One or both of two independent boolean data flags — `mlb` and `personal` — prompted once at `chezmoi init` and persisted in that machine's own `~/.config/chezmoi/chezmoi.toml`. Not mutually exclusive: a machine can carry both roles (e.g. a company-owned machine also used for personal work). Templates and `.chezmoiignore` read these flags to decide which machine-specific Homebrew packages, secrets, git identity, and macOS defaults apply.
_Avoid_: profile, machine type, environment (chezmoi already uses "data" for the underlying mechanism — "role" names this repo's specific two flags, not chezmoi's general templating data).

### Terminal layout (Rex)

**Session**:
One Rex session per repo, labelled with the repo's name. Holds every worktree's tab and every agent working in that repo.
_Avoid_: workspace, project (Rex has no project concept; the session is it).

**Tab**:
One worktree inside a session, labelled with its branch name (`main` for the trunk). Rex's CLI and API call it a `window` (`rex window new`, `window_id`, `session.new_window`); Rex's Mac menus call it a Tab (`client.tab.*`).
_Avoid_: window (in prose), because the Mac app's **macOS window** is a different thing.

**Pane**:
A terminal split inside a tab: the agent, a shell, a test runner. Rex calls it a `block` in the CLI and API.

**macOS window**:
The Mac app's frame onto the server (`client.window.*`, File → New Window). Closing or moving one changes nothing about sessions, tabs or panes. No skill acts on it.
