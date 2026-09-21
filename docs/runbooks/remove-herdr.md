# Removing herdr from a machine

Per-machine cleanup for [ADR-0006](../adr/0006-drop-herdr.md). Chezmoi's repo changes
(the setup script, launchd plist source, `dot_config/herdr/config.toml`, and
`.chezmoiremove` entries for the two orphaned targets) only take effect once pulled and
applied on a given machine — and even then, several things herdr installed live entirely
outside chezmoi's reach and need manual removal. Run this once per machine that has ever
run herdr.

Every step below checks before it acts, so this is safe to re-run or to run on a machine
where some of this was already cleaned up by hand.

## 1. Pull and apply the repo changes first

```sh
chezmoi update --apply
```

This alone removes `~/.config/herdr/` and `~/Library/LaunchAgents/dev.herdr.server.plist`
(via `.chezmoiremove` — deleting a file from chezmoi's source doesn't delete the
already-applied target on its own, hence the explicit entries) and updates every
herdr-aware file (`up.fish`, `02-paths.fish`, `worktrunk/config.toml`,
`cleanup-branch/SKILL.md`) to its herdr-free version. It does **not** stop the running
server first — do that next, before the directory holding its socket disappears out
from under it.

## 2. Stop the background service — `bootout`, not `stop`

```sh
launchctl bootout "gui/$(id -u)/dev.herdr.server" 2>/dev/null || true
```

Deliberately `bootout`, not `herdr server stop`: the launchd job's `KeepAlive` is `true`
(mirrored from herdr's own Homebrew formula — see the now-deleted
`run_after_17-herdr-setup.sh` for why), so a plain `stop` gets immediately relaunched by
launchd. `bootout` unloads the job first, which is what actually keeps it down. The
`|| true` covers the already-clean case (job already unloaded, or step 1 already deleted
the plist) — `launchctl print "gui/$(id -u)/dev.herdr.server"` should report "Could not
find service" afterward either way.

## 3. Remove what chezmoi never touched

None of the following is chezmoi-managed — herdr's own installer and its own runtime put
these here directly, so `chezmoi update --apply` in step 1 has no way to know about them:

```sh
# The curl-installed binary itself, plus any stray update temp files it left behind.
rm -f ~/.local/bin/herdr ~/.local/bin/.herdr-update-*.tmp

# launchd's stdout/stderr log target (the directory the plist pointed at).
rm -rf ~/Library/Logs/herdr

# Runtime state: plugin installs, agent-detection heuristics, client-shell records.
rm -rf ~/.local/state/herdr

# Anything macOS's own crash reporter captured for it.
rm -f ~/Library/Application\ Support/CrashReporter/herdr_*.plist
rm -f ~/Library/Logs/DiagnosticReports/herdr-*.ips
```

## 4. Remove the agent skill through the skills CLI, not a raw `rm`

```sh
npx --yes "skills@1.7.0" remove herdr -g -y
```

Pin the version to match this repo's other `skills` invocations (see `up.fish`,
`run_onchange_after_15-install-agent-skills.sh.tmpl`) so a `skills` release doesn't
silently change removal behavior on one machine before another.

**Don't pass `--agent universal`.** The skill was installed with `--agent universal`,
but `skills remove`'s `--agent` flag filters by the _concrete_ agents the CLI already
detected using that skill (e.g. "GitHub Copilot", "Zed" — check with
`npx --yes "skills@1.7.0" list -g | grep herdr` first if unsure), not by the literal
string `universal` — passing it silently matches nothing and the command still reports
success. Omit `--agent` entirely; per `skills remove --help`, omitting it "clean\[s\] all
agent links."

Using the CLI instead of deleting `~/.agents/skills/herdr` by hand keeps
`~/.agents/.skill-lock.json` consistent — though a stale top-level `"herdr"` entry may
still linger there after removal (observed on one machine: directory gone, `skills list
-g` no longer shows it, but the lock file keeps the key). That's the `skills` CLI's own
bookkeeping bug, not something to hand-edit; it's functionally inert either way.

## 5. Remove the orphaned Pi extension

```sh
rm -f ~/.pi/agent/extensions/herdr-agent-state.ts
```

herdr's own setup installed this directly into Pi's extensions directory — it was never
chezmoi-managed (see AGENTS.md's note on unmanaged extension files) — so it's still
sitting there even after everything above, doing nothing useful now that herdr is gone.

## 6. Verify

```sh
command -v herdr                                    # expect: nothing (not found)
launchctl print "gui/$(id -u)/dev.herdr.server"      # expect: could not find service
brew list 2>/dev/null | grep -i herdr                # expect: nothing (never brew-installed)
find ~ -maxdepth 4 -iname '*herdr*' 2>/dev/null \
  | grep -v '\.local/share/chezmoi' \
  | grep -v '\.cache/homebrew'                       # expect: nothing
```

The last `find` deliberately excludes this repo's own checkout and Homebrew's API cache
— both legitimately still mention herdr by name (this runbook, the ADR, the research
doc; Homebrew's formula-metadata cache for the _string_ "herdr", not an install) and
aren't part of what this cleanup is removing.
