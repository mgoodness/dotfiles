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

## Muxy + worktrunk

Parallel git-worktree development with [Muxy](https://muxy.app) (terminal + UI) and
[worktrunk](https://worktrunk.dev) (`wt`, worktree lifecycle). A fresh
`chezmoi init --apply` wires it up:

1. Homebrew installs `worktrunk`, `mise`, and the Muxy cask.
2. `run_once_after_31-worktrunk-shell.sh` installs worktrunk's fish shell integration.
3. Canonical layouts (`agent` / `dev` / `infra`) deploy to `~/.config/muxy/layouts/`.
4. `~/.config/worktrunk/config.toml` hooks fire on `wt switch --create <branch>`: prep
   env (mise → direnv), symlink the layouts into the new worktree, then register and
   focus it in Muxy.

Two one-time steps Muxy can't script:

- Enable **Settings → General → Auto-expand worktrees on project switch**.
- Create `Personal` / `MLB` sidebar workspaces and assign projects.

Day-to-day: `gh repo clone …` registers the repo as a Muxy project and symlinks the
layouts into its root worktree (run `mise install` yourself to set up env). `wt switch
--create <branch>` spins up an isolated worktree with env prep and layouts done for you.
Either way the layout picker is never automatic — pick one from the top bar once and Muxy
persists it.

## Acknowledgements

- [@branchv](https://github.com/branchv/dotfiles)
- [@injust](https://codeberg.org/jsu/dotfiles)
