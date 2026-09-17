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

| Script                                                 | Does                                                                       |
| ------------------------------------------------------ | -------------------------------------------------------------------------- |
| `run_once_after_10-homebrew.sh`                        | Installs Homebrew if absent, then `brew bundle install`                    |
| `run_onchange_after_11-build-bat-cache.sh.tmpl`        | Rebuilds bat theme cache after theme changes                               |
| `run_onchange_after_12-install-gh-extensions.sh.tmpl`  | Installs `gh` extensions (e.g. `gh-poi`)                                   |
| `run_onchange_after_15-install-agent-skills.sh.tmpl`   | Installs agent skills via `gh skill`                                       |
| `run_once_after_15-bootstrap-mattpocock-skills.sh`     | One-time install of mattpocock/skills' engineering + productivity skills   |
| `run_onchange_after_15-install-claude-plugins.sh.tmpl` | Installs Claude Code plugins                                               |
| `run_after_17-herdr-setup.sh.tmpl`                     | herdr: binary, launchd service, integration, plugins                       |
| `run_onchange_after_20-macos.sh`                       | Sets macOS defaults, Dock layout, Touch ID sudo                            |
| `run_after_21-remote-login.sh.tmpl`                    | Enables Remote Login on the Mac mini only (hostname-gated)                 |
| `run_after_22-authorized-keys.sh.tmpl`                 | Authorizes the MacBook Pro's SSH key on the Mac mini only (hostname-gated) |
| `run_after_30-fish.sh`                                 | Adds fish to `/etc/shells` and sets it as login shell                      |
| `run_after_31-worktrunk-setup.sh`                      | Worktrunk: fish shell integration + Pi extension                           |

## Git hooks (prek)

Commits run [prek](https://prek.j178.dev) through two Git config hooks in `dot_config/git/config`: `hook "prek global"` runs the generic checks from `~/.config/prek/global-hooks.toml` (pinned with `--config`), and `hook "prek repo"` runs the repo's `prek.toml` via discovery (`PREK_ALLOW_NO_CONFIG=1`, so repos without one stay silent). These are global config hooks, not repo-local shims, so both fire for every commit in every repo.

## Architecture

### Git workspace (`Code/`)

Repos organized by git host under `~/Code/`:

- `github.com/` — personal repos
- `emu.github.com/` — MLB GitHub Enterprise (corporate)
- `github.mlbam.net/` — additional corporate host

Each directory has `.gitconfig` overriding identity and signing key. Global git config at `dot_config/git/config` uses `includeIf "gitdir/i:~/Code/{host}/"` to load automatically.

`gh repo clone` (via custom `gh.fish` function) places repos at `~/Code/{host}/{user}/{repo}` (run `mise install` yourself for clone env setup).

### herdr + worktrunk

Parallel worktree development with [herdr](https://herdr.dev) (terminal workspace manager, run inside Ghostty) and [worktrunk](https://worktrunk.dev) (`wt`, worktree lifecycle).

> Ghostty installs via Homebrew (`cask "ghostty"`); herdr installs via its own installer (`run_after_17-herdr-setup.sh.tmpl`, not Homebrew — the curl-installed binary is what supports `herdr update --handoff`).

- **Worktrees**: worktrunk owns create/teardown. The sibling path `repo.branch` keeps each worktree under `~/Code/{host}/`, so per-host identity and signing still apply (ADR-0002). User config: `dot_config/worktrunk/config.toml`.
- **Hooks** (fire on `wt switch --create`): `pre-start` preps env (mise → direnv fallback); `post-start` opens a focused herdr workspace at the worktree.
- **Workspaces**: labeled `Personal` / `MLB` by convention only — herdr has no group/folder primitive to enforce this; see `CONTEXT.md`.
- **Shell integration**: installed by `run_after_31-worktrunk-setup.sh` (`functions/wt.fish`, unmanaged by chezmoi). The same script keeps the Pi activity extension (`~/.pi/agent/extensions/worktrunk.ts`) current; `up.fish`'s `__up_wt` does the same between applies.

Design rationale lives in `CONTEXT.md` (glossary) and `docs/adr/` (ADRs 0001, 0002, 0004).

### Fish shell

- `dot_config/fish/config.fish` — environment variables, tool initialization
- `dot_config/fish/conf.d/abbr.fish` — abbreviations for chezmoi, k8s, git, terraform, docker
- `dot_config/fish/fish_plugins` — Fisher plugin list (source of truth; run `fisher update` to sync)
- `dot_config/fish/functions/` — custom functions (`gh`, `gconfig`, `new-gke`, `k8s-context`, etc.)

On shell startup, `up --auto` checks for daily updates.

### Themes

Catppuccin used across bat, eza, ghostty, Helix, herdr; the first four fetched via `.chezmoiexternal.toml`, not committed — herdr's is built in (`dot_config/herdr/config.toml`), no external fetch needed. Ghostty, Helix, and herdr switch light/dark automatically on system appearance. herdr only ships one dark Catppuccin variant (`catppuccin`, not flavor-named) vs. the Frappe used elsewhere — closest built-in match, not a guaranteed pixel-exact one.

### pi (`pi-coding-agent`)

`dot_pi/agent/modify_settings.json` → `~/.pi/agent/settings.json`, a `chezmoi:modify-template` (note: marker files must _not_ carry the `.tmpl` suffix, which would suppress the modify handling) that **merges** into Pi's existing file instead of replacing it, so runtime state Pi writes itself survives `chezmoi apply`. Profile-aware seeds: `personal` gets OpenRouter/DeepSeek, `mlb` gets GitHub Copilot/Sonnet 5, both `high` thinking — these only fill in when absent, so a Ctrl+S change is never reverted. That seed is per-machine, not per-repo; a directory-scoped override sits on top of it via `dot_config/fish/functions/pi.fish`, which wraps the `pi` binary (`--wraps=pi`) and injects `--provider`/`--model` from `PI_DEFAULT_PROVIDER`/`PI_DEFAULT_MODEL` env vars whenever both are set and the invocation isn't already an explicit `--provider`/`--model` or a subcommand (`install`, `config`, etc.). Those env vars are set only in `Code/github.com/mise.toml.tmpl` alongside `CLOUDSDK_ACTIVE_CONFIG_NAME`, gated behind `{{ if .mlb }}`: personal machines already default to OpenRouter/DeepSeek globally, so only an `mlb`-profile machine needs the override to keep `~/Code/github.com` on OpenRouter/DeepSeek instead of the machine's GitHub Copilot/Sonnet 5 default. `emu.github.com`/`github.mlbam.net` need no override — their `mise.toml` stays a plain (non-template) file, since GitHub Copilot/Sonnet 5 is already the `mlb` global default. `theme` is chezmoi-managed and always wins; the declared npm package is unioned into `packages`; every other key (`lastChangelogVersion`, Pi-added packages) is preserved untouched. Installed via Homebrew (`brew "pi-coding-agent"`). Managed alongside `dot_pi/agent/themes/` — `catppuccin-frappe` (dark) and `catppuccin-latte` (light), auto-selected by the `"<light>/<dark>"` `theme` setting on terminal appearance — and `dot_pi/agent/extensions/openrouter-credits.ts`, a status-line extension that shows the remaining OpenRouter balance (from `/api/v1/credits`) only while that provider is active. It resolves the key through Pi's model registry, so `OPENROUTER_API_KEY` and a `/login`-stored key both work. Unmanaged: `auth.json` (secrets), `models-store.json` (generated cache), `sessions/`, and the extension files other tools install themselves (`worktrunk.ts`, `herdr-agent-state.ts`).

Subagent delegation runs through pi's bundled `subagent` example extension rather than a hand-rolled tool: `dot_pi/agent/extensions/subagent/{symlink_index.ts,symlink_agents.ts}` symlink to the extension shipped inside the `pi-coding-agent` Homebrew formula (`$(brew --prefix pi-coding-agent)/libexec/.../examples/extensions/subagent/`), matching the upstream README's own symlink-based install so a `brew upgrade` picks up improvements automatically. `dot_pi/agent/agents/*.md` are real, owned files, not symlinks — currently just `code-review-spec` and `code-review-standards`, the two purpose-built agents backing the two-axis `code-review` skill's parallel sub-agent dispatch. The upstream sample agents (`scout`, `planner`, `reviewer`, `worker`) and its three bundled workflow prompts (`/implement`, `/scout-and-plan`, `/implement-and-review`) were deliberately dropped rather than kept as unused scaffolding; add new `agents/*.md` files here as real needs come up. None of this needs a `settings.json` entry: `~/.pi/agent/extensions/*/index.ts` is auto-discovered, and `~/.pi/agent/agents/*.md` is a convention the subagent extension's own `discoverAgents()` reads directly — any new agent should have its `model:` frontmatter omitted so it inherits the dispatching session's active model/thinking level instead of a hardcoded one.

### Secrets / signing

All SSH signing through 1Password (`op-ssh-sign`). SSH agent socket: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`. Corporate repos on `emu.github.com` use separate signing key in `Code/emu.github.com/dot_gitconfig`.

## Commit conventions

Follows [Conventional Commits](https://www.conventionalcommits.org/). Template at `dot_config/git/commit`. Scopes: `fish`, `git`, `homebrew`, `macos`, `ghostty`, `zed`, `helix`, `skills`, `herdr`, `mise`, `pi`.

## Agent skills

### Issue tracker

Issues live as GitHub issues on `mgoodness/dotfiles` (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical five-role vocabulary, label strings unchanged. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
