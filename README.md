# Dotfiles [![CI](https://github.com/mgoodness/dotfiles/workflows/CI/badge.svg)](https://github.com/mgoodness/dotfiles/actions?query=workflow%3ACI+branch%3Amain)

macOS workstation setup for my personal and MLB machines — [fish shell](http://fishshell.com/),
[chezmoi](https://www.chezmoi.io/) management, [1Password](https://1password.com/downloads/command-line/)
secrets through [fnox](https://fnox.jdx.dev/), and [Catppuccin](https://catppuccin.com) theming.
[XDG spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)-compliant where possible.

## What's managed

- **Shell** — fish, with the [tide](https://github.com/IlanCosman/tide) prompt, [fisher](https://github.com/jorgebucaran/fisher)
  plugins, and custom functions/abbreviations (`up`, `gh`, `k8s-*`, chezmoi aliases).
- **Secrets** — [fnox](https://fnox.jdx.dev/) resolves keys from 1Password on demand, loaded per-directory
  via `fnox activate fish`; a daemon caches resolved values in memory only.
- **Env & tools** — [mise](https://mise.jdx.dev/) scopes tools and environment variables by directory.
- **Themes** — Catppuccin for bat, eza, ghostty, and Helix, fetched from upstream archives
  (`.chezmoiexternal.toml`, 168h refresh). Macterm and Helix follow the system light/dark appearance.
- **pi** — the [pi](https://pi.dev/) coding agent: homegrown skills (`~/.agents/skills`), global
  extensions, subagent definitions, and npm packages.

## Installation

If you already have `chezmoi`:

```sh
chezmoi init --apply mgoodness
```

Otherwise:

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply mgoodness
```

`chezmoi init` prompts for two independent **roles** — `mlb` and `personal` — which gate
machine-specific Homebrew packages, secrets, git identity, and macOS defaults. A machine can
carry both.

After applying, `.chezmoiscripts/` installs Homebrew packages (`brew bundle`), gh extensions,
pi packages, and agent skills; sets macOS defaults; configures fish as the login shell; and
wires up worktrunk.

## Development workflow

Repos live under `~/Code/` by git host — `github.com/`, `emu.github.com/`, and
`github.mlbam.net/` — each with its own `.gitconfig` for identity and signing (1Password
`op-ssh-sign`). `gh repo clone` places a repo at `~/Code/{host}/{user}/{repo}` (run `mise
install` yourself for a plain clone).

Parallel work happens in git worktrees via [worktrunk](https://worktrunk.dev) (`wt`), run inside
Macterm. A fresh `chezmoi init --apply` installs `worktrunk` and the `macterm` cask, and
`run_after_31-worktrunk-setup.sh` wires up worktrunk's fish integration and pi activity extension.
The `pre-start` hook in `~/.config/worktrunk/config.toml` preps env (mise → direnv) on
`wt switch --create <branch>`, so each new worktree is ready to go.

## Acknowledgements

- [@branchv](https://github.com/branchv/dotfiles)
- [@injust](https://codeberg.org/jsu/dotfiles)
