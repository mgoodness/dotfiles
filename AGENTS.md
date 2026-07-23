# AGENTS.md

Guidance for coding agents working in this repo.

## What this repo is

[chezmoi](https://www.chezmoi.io/) dotfiles repo. `dot_` prefix → dotfiles in `$HOME` (e.g., `dot_config/fish/config.fish` → `~/.config/fish/config.fish`). `symlink_` prefix → symlinks. `.chezmoiscripts/` run after `chezmoi apply`.

## Chezmoi workflow

```sh
chezmoi apply              # apply dotfiles to ~
chezmoi diff               # preview what would change
chezmoi edit ~/.config/fish/config.fish   # edit source for a target file
chezmoi add ~/.config/foo  # bring an existing file under chezmoi management
chezmoi update             # pull latest + apply
```

External resources (`.chezmoiexternal.toml`) fetched from remote archives on 168-hour refresh cycle. Force refresh: `chezmoi update --force`.

## Post-apply scripts

Scripts in `.chezmoiscripts/` run in alphanumeric order after `chezmoi apply`. `run_once_*` run once per machine; `run_onchange_*` re-run when a watched file changes; `run_after_*` run on every apply. Guard with condition checks for idempotency.

| Script                                                 | Does                                                      |
| ------------------------------------------------------ | --------------------------------------------------------- |
| `run_once_after_10-homebrew.sh`                        | Installs Homebrew if absent, then `brew bundle install`   |
| `run_onchange_after_11-build-bat-cache.sh.tmpl`        | Rebuilds bat theme cache after theme changes              |
| `run_onchange_after_12-install-gh-extensions.sh.tmpl`  | Installs `gh` extensions (e.g. `gh-poi`)                  |
| `run_onchange_after_15-install-agent-skills.sh.tmpl`   | Installs agent skills via `skl`                           |
| `run_onchange_after_15-install-claude-plugins.sh.tmpl` | Installs Claude Code plugins                              |
| `run_once_after_16-register-fff-mcp.sh`                | Registers the `fff` MCP server (brew installs the binary) |
| `run_after_17-herdr-setup.sh.tmpl`                     | herdr: binary, launchd service, integration, plugins      |
| `run_onchange_after_20-macos.sh`                       | Sets macOS defaults, Dock layout, Touch ID sudo           |
| `run_after_30-fish.sh`                                 | Adds fish to `/etc/shells` and sets it as login shell     |
| `run_once_after_31-worktrunk-shell.sh`                 | Installs worktrunk's fish shell integration               |

## Architecture

### Git workspace (`Code/`)

Repos organized by git host under `~/Code/`:

- `github.com/` — personal repos
- `emu.github.com/` — MLB GitHub Enterprise (corporate)
- `github.mlbam.net/` — additional corporate host

Each directory has `.gitconfig` overriding identity and signing key. Global git config at `dot_config/git/config` uses `includeIf "gitdir/i:~/Code/{host}/"` to load automatically.

`gh repo clone` (via custom `gh.fish` function) places repos at `~/Code/{host}/{user}/{repo}` and opens the clone as a focused herdr workspace (run `mise install` yourself for clone env setup).

### herdr + worktrunk

Parallel worktree development with [herdr](https://herdr.dev) (terminal workspace manager, run inside Ghostty) and [worktrunk](https://worktrunk.dev) (`wt`, worktree lifecycle).

> Ghostty installs via Homebrew (`cask "ghostty"`); herdr installs via its own installer (`run_once_after_17-install-herdr.sh`, not Homebrew — the curl-installed binary is what supports `herdr update --handoff`). The legacy `cmux` cask stays installed alongside both for now — scheduled for removal once the transition is done, not yet.

- **Worktrees**: worktrunk owns create/teardown. The sibling path `repo.branch` keeps each worktree under `~/Code/{host}/`, so per-host identity and signing still apply (ADR-0002). User config: `dot_config/worktrunk/config.toml`.
- **Hooks** (fire on `wt switch --create`): `pre-start` preps env (mise → direnv fallback); `post-start` opens a focused herdr workspace at the worktree.
- **Workspaces**: labeled `Personal` / `MLB` by convention only — herdr has no group/folder primitive to enforce this; see `CONTEXT.md`.
- **Shell integration**: installed by `run_once_after_31-worktrunk-shell.sh` (`functions/wt.fish`, unmanaged by chezmoi).

Design rationale lives in `CONTEXT.md` (glossary) and `docs/adr/` (ADRs 0001, 0002, 0004).

### Fish shell

- `dot_config/fish/config.fish` — environment variables, tool initialization
- `dot_config/fish/conf.d/abbr.fish` — abbreviations for chezmoi, k8s, git, terraform, docker
- `dot_config/fish/fish_plugins` — Fisher plugin list (source of truth; run `fisher update` to sync)
- `dot_config/fish/functions/` — custom functions (`gh`, `gconfig`, `new-gke`, `k8s-context`, etc.)

On shell startup, `up --auto` checks for daily updates.

### Themes

Catppuccin used across bat, eza, ghostty, Helix, herdr; the first four fetched via `.chezmoiexternal.toml`, not committed — herdr's is built in (`dot_config/herdr/config.toml`), no external fetch needed. Ghostty, Zed, Helix, and herdr switch light/dark automatically on system appearance. herdr only ships one dark Catppuccin variant (`catppuccin`, not flavor-named) vs. the Frappe used elsewhere — closest built-in match, not a guaranteed pixel-exact one.

### Secrets / signing

All SSH signing through 1Password (`op-ssh-sign`). SSH agent socket: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`. Corporate repos on `emu.github.com` use separate signing key in `Code/emu.github.com/dot_gitconfig`.

## Commit conventions

Follows [Conventional Commits](https://www.conventionalcommits.org/). Template at `dot_config/git/commit`. Scopes: `fish`, `git`, `homebrew`, `macos`, `ghostty`, `zed`, `helix`, `skills`, `cmux`, `herdr`.

## Agent skills

### Issue tracker

Issues live as GitHub issues on `mgoodness/dotfiles` (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical five-role vocabulary, label strings unchanged. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
