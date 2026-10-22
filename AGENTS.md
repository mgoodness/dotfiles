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

| Script                                                | Does                                                                       |
| ----------------------------------------------------- | -------------------------------------------------------------------------- |
| `run_once_after_10-homebrew.sh`                       | Installs Homebrew if absent, then `brew bundle install`                    |
| `run_onchange_after_11-build-bat-cache.sh.tmpl`       | Rebuilds bat theme cache after theme changes                               |
| `run_onchange_after_12-install-gh-extensions.sh.tmpl` | Installs `gh` extensions (e.g. `gh-poi`)                                   |
| `run_onchange_after_13-reconcile-pi-packages.sh.tmpl` | Uninstalls retired, then installs declared, pi packages                    |
| `run_once_after_14-remove-claude.sh`                  | One-time removal of Claude, its Claude Code data and ClaudeBar             |
| `run_once_after_15-bootstrap-mattpocock-skills.sh`    | One-time install of mattpocock/skills' engineering + productivity skills   |
| `run_onchange_after_15-install-agent-skills.sh.tmpl`  | Installs agent skills via `skills` (vercel-labs/skills)                    |
| `run_once_after_16-remove-tailscale-lazygit.sh`       | One-time removal of lazygit and Tailscale (app, receipt, VPN service)      |
| `run_once_after_18-prune-pi-anthropic-oauth.sh`       | One-time removal of the retired Anthropic OAuth credential                 |
| `run_onchange_after_20-macos.sh`                      | Sets macOS defaults, Dock layout, Touch ID sudo                            |
| `run_after_21-remote-login.sh.tmpl`                   | Enables Remote Login on the Mac mini only (hostname-gated)                 |
| `run_after_22-authorized-keys.sh.tmpl`                | Authorizes the MacBook Pro's SSH key on the Mac mini only (hostname-gated) |
| `run_after_30-fish.sh`                                | Adds fish to `/etc/shells` and sets it as login shell                      |
| `run_after_31-worktrunk-setup.sh`                     | Worktrunk: fish shell integration + Pi extension                           |

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

### worktrunk

Parallel git-worktree development via [worktrunk](https://worktrunk.dev) (`wt`, worktree lifecycle), run inside Macterm.

> Macterm installs via Homebrew (`cask "thdxg/tap/macterm"`) and reads the kept Ghostty config (`dot_config/ghostty/`).

- **Worktrees**: worktrunk owns create/teardown. The sibling path `repo.branch` keeps each worktree under `~/Code/{host}/`, so per-host identity and signing still apply (ADR-0002). User config: `dot_config/worktrunk/config.toml`.
- **Hooks** (fire on `wt switch --create`): `pre-start` preps env (mise → direnv fallback). There's no `post-start` hook anymore — it used to open a herdr workspace at the new worktree; herdr is gone (ADR-0006), so a fresh worktree no longer opens any UI/pane for you automatically.
- **Shell integration**: installed by `run_after_31-worktrunk-setup.sh` (`functions/wt.fish`, unmanaged by chezmoi). The same script keeps the Pi activity extension (`~/.pi/agent/extensions/worktrunk.ts`) current; `up.fish`'s `__up_wt` does the same between applies.

Design rationale lives in `CONTEXT.md` (glossary) and `docs/adr/` (ADRs 0001, 0002, 0004, 0006).

### Homebrew

On mlb machines the corporate MDM (Kandji/Iru) installs some apps as root-owned pkgs: the receipt is named `<App>-<version>-component.pkg`, and the bundle in `/Applications` is a real `root:admin` directory rather than Homebrew's symlink into `Caskroom/`. Declaring such an app in a Brewfile leaves two disagreeing copies, so `brew list --cask` reports the stale staged version and `brew upgrade --cask <name>` aborts with `It seems there is already an App at '…/Caskroom/<name>/<old version>/<App>.app'` — the uninstall step tries to move the old app back into `Caskroom/` before the new one lands and finds the staged copy already there. Slack, Rectangle and Discord are the current cases: Slack is MDM-provided and stays out of `Brewfile.mlb` entirely, while Rectangle and Discord live in `Brewfile.personal` so personal machines still get them from brew. Check before adding an app: `pkgutil --pkgs` for the `<App>-<version>-component.pkg` receipt and `stat -f %Su /Applications/<App>.app` for a `root` owner. Plain `brew upgrade` and `brew bundle` already skip `auto_updates` casks, so the conflict only surfaces on an explicit or `--greedy` upgrade.

### Fish shell

- `dot_config/fish/config.fish` — environment variables, tool initialization
- `dot_config/fish/conf.d/abbr.fish` — abbreviations for chezmoi, k8s, git, terraform, docker
- `dot_config/fish/fish_plugins` — Fisher plugin list (source of truth; run `fisher update` to sync)
- `dot_config/fish/functions/` — custom functions (`gh`, `gconfig`, `new-gke`, `k8s-context`, etc.)

On shell startup, `up --auto` checks for daily updates.

### Themes

Catppuccin used across bat, eza, ghostty, and Helix, fetched via `.chezmoiexternal.toml`, not committed. Macterm (via the kept Ghostty config) and Helix switch light/dark automatically on system appearance.

### pi (`pi-coding-agent`)

`dot_pi/agent/modify_settings.json` → `~/.pi/agent/settings.json`, a `chezmoi:modify-template` (note: marker files must _not_ carry the `.tmpl` suffix, which would suppress the modify handling) that **merges** into Pi's existing file instead of replacing it, so runtime state Pi writes itself survives `chezmoi apply`. The seed is profile-scoped: `.mlb` machines get `github-copilot`/`claude-sonnet-5.5`, every other profile gets `deepseek`/`deepseek-flash`, both with `high` thinking. Those only fill in when absent, so a Ctrl+S change is never reverted — an already-seeded machine keeps whatever model it last saved, so a profile whose seed differs must be changed by hand once. That seed is per-machine, not per-repo. The mlb side pins a concrete model id because the Copilot catalog exposes no `claude-sonnet` alias (ids are `claude-sonnet-4.6`, `claude-sonnet-5`, `claude-sonnet-5.5`, …) and `findInitialModel` resolves the saved default by exact id — an alias would fall through to the first available model instead of erroring, so bump the pin when a newer Sonnet lands. Packages are declared once in `.chezmoidata/pi-packages.toml` and unioned into `packages` by `modify_settings.json`; declaring a package there only makes pi load it once it's actually fetched, so `run_onchange_after_13-reconcile-pi-packages.sh.tmpl` runs `pi install` for each declared package on every apply where that data file changes (currently `@upstash/context7-pi` for the `context7-docs` skill, `pi-exa` for Exa-powered web search/fetch and deep research, and `pi-usage-live` for a docked, always-on-screen provider subscription/quota usage card). `GEMINI_API_KEY` and `OPENCODE_API_KEY` follow the `OPENROUTER_API_KEY` split (nothing is a default provider on an mlb box, so no provider key needs a global scope) rather than a single site — the personal branch of `dot_config/fnox/config.toml.tmpl` for personal machines, plus a copy in `Code/github.com/fnox.toml.tmpl` so the personal-billed key is exported only inside the personal-repos tree on an MLB box, never while working in an emu.github.com or github.mlbam.net tree. Removing a package takes a second edit: an id moved from `[[piPackages]]` to the file's `[[retiredPiPackages]]` list is uninstalled by that same script on every machine, because deleting the entry alone would leave `settings.json` still naming it — the modify template only ever unions declared ids into `packages` and never prunes (`@gotgenes/pi-anthropic-auth` and `@amaster.ai/pi-image-gen` are the entries there; `run_once_after_18-prune-pi-anthropic-oauth.sh` also deletes the Claude OAuth credential that extension existed to make workable, but only where that `auth.json` entry is OAuth rather than an API key and `settings.json` doesn't default to provider `anthropic` — pruning there would change which model Pi starts with). A directory-scoped model override sits on top of the seed via `dot_pi/agent/extensions/directory-default-model.ts`, a global pi extension that reads `PI_DEFAULT_PROVIDER`/`PI_DEFAULT_MODEL` on `session_start` (`reason: "startup"` only, so a resumed/forked/`/new` session keeps whatever model it already recorded) and calls `pi.setModel()` when both are set and neither `--provider` nor `--model` was passed on the invocation. Because mise scopes `[env]` by directory the same way it scopes tool versions, the extension needs no directory-matching logic of its own — it fires for every `pi` invocation but only acts where mise has those two vars set. No `Code/{host}/mise.toml` sets `PI_DEFAULT_PROVIDER`/`PI_DEFAULT_MODEL` today: the seeds above are already per-profile, so a per-directory override would only duplicate the decision (and the pinned Copilot id) in a second place. The extension stays installed as the mechanism for any future case where one host tree needs a model the machine's profile seed does not cover. `theme` is chezmoi-managed and always wins; every other key (`lastChangelogVersion`, Pi-added packages) is preserved untouched. Installed via Homebrew (`brew "pi-coding-agent"`). Managed alongside `dot_pi/agent/themes/` — `catppuccin-frappe` (dark) and `catppuccin-latte` (light), auto-selected by the `"<light>/<dark>"` `theme` setting on terminal appearance — and `dot_pi/agent/extensions/directory-default-model.ts` (above). Unmanaged: `auth.json` (secrets, apart from that one-time OAuth prune), `models-store.json` (generated cache), `sessions/`, and the extension files other tools install themselves (`worktrunk.ts`).

Homegrown skills — `argocd-akuity`, `cleanup-branch`, `fan-out`, `github-app-token`, `go-ci`, `macterm`, `release-please`, `repo-hardening`, `split-commits` — live directly in this repo at `dot_agents/skills/<name>/SKILL.md` (→ `~/.agents/skills/<name>/`, one of pi's own global skill-discovery locations, so no `settings.json` entry is needed either). `argocd-akuity` is mlb-only: `.chezmoiignore` ignores `.agents/skills/argocd-akuity` when `not .mlb`, so it is never deployed on personal machines (same profile-gating pattern as `Brewfile.mlb`; note that ignoring a path is permanent for already-deployed copies, since `.chezmoiremove` cannot remove an ignored target). Keeping them here means edits land as ordinary chezmoi commits and `up skills`' blanket `skills update -g -y` cannot silently overwrite a local tweak with the upstream version.

Subagent delegation runs through pi's bundled `subagent` example extension rather than a hand-rolled tool: `dot_pi/agent/extensions/subagent/{symlink_index.ts,symlink_agents.ts}` symlink to the extension shipped inside the `pi-coding-agent` Homebrew formula (`$(brew --prefix pi-coding-agent)/libexec/.../examples/extensions/subagent/`), matching the upstream README's own symlink-based install so a `brew upgrade` picks up improvements automatically. `dot_pi/agent/agents/*.md` are real, owned files, not symlinks — currently `code-review-spec` and `code-review-standards` (backing the two-axis `code-review` skill's parallel sub-agent dispatch) and `research` (backing the `research` skill's background investigation delegation). The upstream sample agents (`scout`, `planner`, `reviewer`, `worker`) and its three bundled workflow prompts (`/implement`, `/scout-and-plan`, `/implement-and-review`) were deliberately dropped rather than kept as unused scaffolding; add new `agents/*.md` files here as real needs come up. None of this needs a `settings.json` entry: `~/.pi/agent/extensions/*/index.ts` is auto-discovered, and `~/.pi/agent/agents/*.md` is a convention the subagent extension's own `discoverAgents()` reads directly — any new agent should have its `model:` frontmatter omitted so it inherits the dispatching session's active model/thinking level instead of a hardcoded one.

### Secrets / signing

All SSH signing through 1Password (`op-ssh-sign`). SSH agent socket: `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`. Corporate repos on `emu.github.com` use separate signing key in `Code/emu.github.com/dot_gitconfig`.

## Commit conventions

Follows [Conventional Commits](https://www.conventionalcommits.org/). Template at `dot_config/git/commit`. Scopes: `fish`, `git`, `homebrew`, `macos`, `ghostty`, `helix`, `skills`, `mise`, `pi`.

## Agent skills

### Issue tracker

Issues live as GitHub issues on `mgoodness/dotfiles` (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical five-role vocabulary, label strings unchanged. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
