# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A [chezmoi](https://www.chezmoi.io/) dotfiles repository. Files prefixed with `dot_` map to dotfiles in `$HOME` (e.g., `dot_config/fish/config.fish` → `~/.config/fish/config.fish`). Files prefixed with `symlink_` create symlinks. Scripts in `.chezmoiscripts/` run automatically after `chezmoi apply`.

## Chezmoi workflow

```sh
chezmoi apply              # apply dotfiles to ~
chezmoi diff               # preview what would change
chezmoi edit ~/.config/fish/config.fish   # edit source for a target file
chezmoi add ~/.config/foo  # bring an existing file under chezmoi management
chezmoi update             # pull latest + apply
```

External resources (`.chezmoiexternal.toml`) are fetched from remote archives on a 168-hour refresh cycle. Force a refresh with `chezmoi update --force`.

## Post-apply scripts

Scripts in `.chezmoiscripts/` run in alphanumeric order after `chezmoi apply`. `run_after_*` scripts are idempotent and guard against re-running with condition checks. `run_onchange_*` scripts re-run whenever the file they watch changes.

| Script                                  | Does                                                    |
| --------------------------------------- | ------------------------------------------------------- |
| `run_after_10-homebrew.sh`              | Installs Homebrew if absent, then `brew bundle install` |
| `run_after_20-macos.sh`                 | Sets macOS defaults, Dock layout, Touch ID sudo         |
| `run_after_30-fish.sh`                  | Adds fish to `/etc/shells` and sets it as login shell   |
| `run_onchange_build-bat-cache.sh`       | Rebuilds bat theme cache after theme changes            |
| `run_onchange_install-gh-extensions.sh` | Installs `gh-poi` extension                             |

## Architecture

### Git workspace (`Code/`)

Repos are organized by git host under `~/Code/`:

- `github.com/` — personal repos
- `emu.github.com/` — MLB GitHub Enterprise (corporate)
- `github.mlbam.net/` — additional corporate host

Each directory has a `.gitconfig` that overrides identity and signing key for that workspace. The global git config at `dot_config/git/config` uses `includeIf "gitdir/i:~/Code/{host}/"` to load these automatically.

`gh repo clone` (via the custom `gh.fish` function) automatically places repos at `~/Code/{host}/{user}/{repo}`.

### Fish shell

- `dot_config/fish/config.fish` — environment variables, tool initialization
- `dot_config/fish/conf.d/abbr.fish` — abbreviations for chezmoi, k8s, git, terraform, docker
- `dot_config/fish/fish_plugins` — Fisher plugin list (source of truth; run `fisher update` to sync)
- `dot_config/fish/functions/` — custom functions (`gh`, `gconfig`, `new-gke`, `k8s-context`, etc.)

On shell startup, `up --auto` runs to check for daily updates.

### Themes

Catppuccin is used across bat, eza, and ghostty; themes are fetched via `.chezmoiexternal.toml` and are not committed. Ghostty and Zed switch light/dark automatically based on system appearance.

### Secrets / signing

All SSH signing goes through 1Password (`op-ssh-sign`). The SSH agent socket is `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`. Corporate repos on `emu.github.com` use a separate signing key defined in `Code/emu.github.com/dot_gitconfig`.

## Commit conventions

This repo follows [Conventional Commits](https://www.conventionalcommits.org/). A commit template lives at `dot_config/git/commit`. Typical scopes: `fish`, `nvim`, `git`, `homebrew`, `macos`, `ghostty`, `zed`, `bat`.
