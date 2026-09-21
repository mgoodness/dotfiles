# Dotfiles [![CI](https://github.com/mgoodness/dotfiles/workflows/CI/badge.svg)](https://github.com/mgoodness/dotfiles/actions?query=workflow%3ACI+branch%3Amain)

- [fish shell](http://fishshell.com/) on macOS
- [XDG spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)-compliant (where possible)
- [chezmoi](https://www.chezmoi.io/) for management
- [1Password](https://1password.com/downloads/command-line/) for secrets
- [Catppuccin](https://catppuccin.com) for themes

## Installation

If you already have `chezmoi`:

```sh
chezmoi init --apply mgoodness
```

Otherwise:

```sh
sh -c "$(curl -fsLS get.chezmoi.io/lb)" -- init --apply mgoodness
```

## worktrunk

Parallel git-worktree development with [worktrunk](https://worktrunk.dev) (`wt`,
worktree lifecycle), run inside Ghostty. A fresh `chezmoi init --apply` wires it up:

1. Homebrew installs `worktrunk`, `mise`, and the `ghostty` cask.
2. `run_after_31-worktrunk-setup.sh` installs worktrunk's fish shell integration and
   its Pi activity extension.
3. `~/.config/worktrunk/config.toml`'s `pre-start` hook fires on `wt switch --create <branch>`: prep env (mise → direnv).

Day-to-day: `gh repo clone …` places the repo at `~/Code/{host}/{user}/{repo}` (run `mise
install` yourself to set up env). `wt switch --create <branch>` spins up an isolated
worktree with env prep done for you.

## Acknowledgements

- [@branchv](https://github.com/branchv/dotfiles)
- [@injust](https://codeberg.org/jsu/dotfiles)
