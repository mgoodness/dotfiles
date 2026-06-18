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

| Script                                                 | Does                                                    |
| ------------------------------------------------------ | ------------------------------------------------------- |
| `run_once_after_10-homebrew.sh`                        | Installs Homebrew if absent, then `brew bundle install` |
| `run_onchange_after_11-build-bat-cache.sh.tmpl`        | Rebuilds bat theme cache after theme changes            |
| `run_onchange_after_12-install-gh-extensions.sh.tmpl`  | Installs `gh` extensions (e.g. `gh-poi`)                |
| `run_onchange_after_15-install-agent-skills.sh.tmpl`   | Installs agent skills via `skl`                         |
| `run_onchange_after_15-install-claude-plugins.sh.tmpl` | Installs Claude Code plugins                            |
| `run_onchange_after_16-install-fff-mcp.sh.tmpl`        | Installs the `fff` MCP server                           |
| `run_onchange_after_20-macos.sh`                       | Sets macOS defaults, Dock layout, Touch ID sudo         |
| `run_after_30-fish.sh`                                 | Adds fish to `/etc/shells` and sets it as login shell   |
| `run_once_after_31-worktrunk-shell.sh`                 | Installs worktrunk's fish shell integration             |

## Architecture

### Git workspace (`Code/`)

Repos organized by git host under `~/Code/`:

- `github.com/` — personal repos
- `emu.github.com/` — MLB GitHub Enterprise (corporate)
- `github.mlbam.net/` — additional corporate host

Each directory has `.gitconfig` overriding identity and signing key. Global git config at `dot_config/git/config` uses `includeIf "gitdir/i:~/Code/{host}/"` to load automatically.

`gh repo clone` (via custom `gh.fish` function) places repos at `~/Code/{host}/{user}/{repo}`, registers the clone as a Muxy project, and symlinks the canonical layouts into its root worktree (run `mise install` yourself for clone env setup).

### Muxy + worktrunk

Parallel worktree development with [Muxy](https://muxy.app) (terminal/UI) and [worktrunk](https://worktrunk.dev) (`wt`, worktree lifecycle).

- **Worktrees**: worktrunk owns create/teardown. The sibling path `repo.branch` keeps each worktree under `~/Code/{host}/`, so per-host identity and signing still apply (ADR-0002). User config: `dot_config/worktrunk/config.toml`.
- **Hooks** (fire on `wt switch --create`): `pre-start` preps env (mise → direnv fallback) and symlinks the canonical layouts into the worktree; `post-start` registers and focuses the worktree in Muxy.
- **Layouts**: `agent` / `dev` / `infra` live at `dot_config/muxy/layouts/` → `~/.config/muxy/layouts/`, global-ignored — never committed (ADR-0003). Symlinked into a worktree's `.muxy/layouts/` by the `pre-start` hook (new worktrees) and by `gh.fish` (a clone's root). Never auto-applied — pick once from the top-bar picker and Muxy persists it.
- **Workspaces**: `Personal` / `MLB` sidebar filters, assigned manually (no Muxy CLI).
- **Shell integration**: installed by `run_once_after_31-worktrunk-shell.sh` (`functions/wt.fish`, unmanaged by chezmoi).
- **Retrofit**: `muxy-retrofit` backfills the layout symlink into every existing Muxy worktree (skips `$HOME` and non-git dirs) — run it for projects that predate this wiring.

Design rationale lives in `CONTEXT.md` (glossary) and `docs/adr/` (ADRs 0001–0004).

### Fish shell

- `dot_config/fish/config.fish` — environment variables, tool initialization
- `dot_config/fish/conf.d/abbr.fish` — abbreviations for chezmoi, k8s, git, terraform, docker
- `dot_config/fish/fish_plugins` — Fisher plugin list (source of truth; run `fisher update` to sync)
- `dot_config/fish/functions/` — custom functions (`gh`, `gconfig`, `new-gke`, `k8s-context`, `muxy-retrofit`, etc.)

On shell startup, `up --auto` checks for daily updates.

### Themes

Catppuccin used across bat, eza, ghostty, Helix; fetched via `.chezmoiexternal.toml`, not committed. Ghostty, Zed, and Helix switch light/dark automatically on system appearance.

### Secrets / signing

All SSH signing through 1Password (`op-ssh-sign`). SSH agent socket: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`. Corporate repos on `emu.github.com` use separate signing key in `Code/emu.github.com/dot_gitconfig`.

## Commit conventions

Follows [Conventional Commits](https://www.conventionalcommits.org/). Template at `dot_config/git/commit`. Scopes: `fish`, `git`, `homebrew`, `macos`, `ghostty`, `zed`, `helix`, `skills`, `muxy`.

## Agent skills

### Issue tracker

Issues live as GitHub issues on `mgoodness/dotfiles` (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical five-role vocabulary, label strings unchanged. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
