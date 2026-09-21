#!/usr/bin/env bash
# shellcheck shell=bash

# Everything herdr needs: install the binary, load its background service,
# then configure application-level extras (the agent skill, the Pi
# integration, the worktrunk plugin). Runs every apply — every step below
# guards itself before acting, so this fully self-heals (including the
# binary: unlike a run_once script, a manually-deleted ~/.local/bin/herdr
# gets reinstalled on the next apply instead of chezmoi silently believing
# that step already succeeded).

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

export PATH="$HOME/.local/bin:$PATH"

# 1. Binary — install via herdr's official installer, not Homebrew, since the
# curl-installed binary is what supports `herdr update --handoff` for
# in-place session updates.
if ! command -v herdr >/dev/null 2>&1; then
    echo "Installing herdr..."
    curl -fsSL https://herdr.dev/install.sh | sh
fi

if ! command -v herdr >/dev/null 2>&1; then
    echo "Skipping herdr service/extras: herdr install failed or not on PATH"
    exit
fi

# 2. Service — launchd agent (Library/LaunchAgents/dev.herdr.server.plist.tmpl)
# with keep_alive: true, mirrored from herdr's own Homebrew formula's `service
# do` block (`brew cat herdr`) — authoritative since herdr's maintainers wrote
# it, and confirms keep_alive doesn't fight `herdr update --handoff`. One
# deviation from that formula: an explicit ThrottleInterval of 1s. `herdr
# --remote`'s own graceful-restart flow (prompted when the remote server
# predates SSH-drop-safe handling) kills the server and polls for a fresh one
# for only ~5s; launchd's default 10s crash-loop throttle can make that
# single legitimate respawn look like it never happened, from the client's
# point of view. Confirmed via herdr.log on mikes-mac-mini: the respawn
# itself succeeds, it just isn't fast enough for that poll without this.
PLIST="$HOME/Library/LaunchAgents/dev.herdr.server.plist"
if [ -f "$PLIST" ]; then
    mkdir -p "$HOME/Library/Logs/herdr"
    GUI_DOMAIN="gui/$(id -u)"
    if ! launchctl print "$GUI_DOMAIN/dev.herdr.server" >/dev/null 2>&1; then
        echo "Loading herdr background service..."
        launchctl bootstrap "$GUI_DOMAIN" "$PLIST"
    fi
else
    echo "Skipping herdr service: $PLIST not found"
fi

# 3. Extras — agent skill, Pi integration, worktrunk plugin. `herdr
# integration install` and `herdr plugin install` are safe to re-run on
# something already installed (verified: no error, no duplication), so the
# only guard needed is "skip if already current". Checking the target
# individually also bootstraps it when not yet installed, and reinstalls it
# when a herdr upgrade bumps the bundled integration version. Pi is the only
# agent this machine uses; up.fish keeps it current between applies.

# Pinned so a `skills` release doesn't silently change apply behavior on one
# machine before another. Bump deliberately, in lockstep with the same pin in
# the other skills-install chezmoiscripts and `up.fish`.
skills_version="1.7.0"
if command -v npx &>/dev/null; then
    # "universal" writes only into ~/.agents/skills, the location pi (and any
    # other harness honoring the shared-skills convention) already discovers
    # on its own. Targeting "pi" here instead would make the CLI additionally
    # copy the skill into ~/.pi/agent/skills, a second, independently-updated
    # copy pi also scans — pi then reports it as a name collision between the
    # two identical locations.
    #
    # `skills add` is chatty on every call (clone spinner, install summary, a
    # Socket/Snyk security-scan table) even on success. Swallow that unless
    # the call actually fails. --json is load-bearing here, not just for
    # parsing: without it, the human-readable mode exits 0 even on a hard
    # failure (bad repo, bad skill name), so a real failure would otherwise
    # go unnoticed.
    if ! out=$(npx --yes "skills@${skills_version}" add herdrdev/herdr --skill herdr --agent universal -g -y --json 2>&1); then
        printf '%s\n' "$out" >&2
    fi
fi

integration_status="$(herdr integration status 2>/dev/null)"
if ! grep -q "^pi: current" <<<"$integration_status"; then
    echo "Installing herdr pi integration..."
    herdr integration install pi
fi

installed_plugins="$(herdr plugin list --json 2>/dev/null)"

if ! jq -e --arg id "devashish2203/herdr-worktrunk" '.result.plugins | any((.source.owner + "/" + .source.repo) == $id)' <<<"$installed_plugins" >/dev/null 2>&1; then
    echo "Installing herdr plugin devashish2203/herdr-worktrunk..."
    herdr plugin install devashish2203/herdr-worktrunk --yes
fi
