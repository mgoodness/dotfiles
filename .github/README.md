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

## cmux + worktrunk

Parallel git-worktree development with [cmux](https://cmux.com) (terminal + UI) and
[worktrunk](https://worktrunk.dev) (`wt`, worktree lifecycle). A fresh
`chezmoi init --apply` wires it up:

1. Homebrew installs `worktrunk`, `mise`, and the cmux cask.
2. `run_once_after_31-worktrunk-shell.sh` installs worktrunk's fish shell integration.
3. `~/.config/worktrunk/config.toml` hooks fire on `wt switch --create <branch>`: prep
   env (mise → direnv), then open a focused cmux workspace at the new worktree.

One one-time step cmux can't script: create the `Personal` / `MLB` sidebar workspace
groups (`cmux workspace-group create`) and assign projects to them.

Day-to-day: `gh repo clone …` opens the repo as a focused cmux workspace (run `mise
install` yourself to set up env). `wt switch --create <branch>` spins up an isolated
worktree with env prep and a focused cmux workspace, done for you.

## Acknowledgements

- [@branchv](https://github.com/branchv/dotfiles)
- [@injust](https://codeberg.org/jsu/dotfiles)
