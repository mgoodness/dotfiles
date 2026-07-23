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

## herdr + worktrunk

Parallel git-worktree development with [herdr](https://herdr.dev) (terminal workspace
manager, run inside Ghostty) and [worktrunk](https://worktrunk.dev) (`wt`, worktree
lifecycle). A fresh `chezmoi init --apply` wires up the worktrunk half:

1. Homebrew installs `worktrunk`, `mise`, and the `ghostty` cask (the legacy `cmux`
   cask still installs alongside, for now).
2. `run_once_after_17-install-herdr.sh` installs herdr via its own installer — not
   Homebrew, so `herdr update --handoff` (in-place session updates) keeps working.
3. `run_once_after_31-worktrunk-shell.sh` installs worktrunk's fish shell integration.
4. `~/.config/worktrunk/config.toml` hooks fire on `wt switch --create <branch>`: prep
   env (mise → direnv), then open a focused herdr workspace at the new worktree.

Workspaces are labeled `Personal` / `MLB` by convention only — herdr has no
group/folder primitive to enforce this the way cmux's sidebar groups did.

Day-to-day: `gh repo clone …` opens the repo as a focused herdr workspace (run `mise
install` yourself to set up env). `wt switch --create <branch>` spins up an isolated
worktree with env prep and a focused herdr workspace, done for you.

## Acknowledgements

- [@branchv](https://github.com/branchv/dotfiles)
- [@injust](https://codeberg.org/jsu/dotfiles)
