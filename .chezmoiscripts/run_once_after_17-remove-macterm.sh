#!/usr/bin/env bash
# shellcheck shell=bash

# One-time removal of Macterm, replaced by Rex (docs/adr/0008-macterm-to-rex.md).
#
# `brew uninstall --cask --zap` handles whatever the cask's own `zap` stanza
# lists; the rm -rf afterwards catches Macterm's per-user state in case a
# machine never installed it via Homebrew, or the stanza misses something
# (projects.json / workspaces_v3.json under Application Support, the
# preferences plist, caches, HTTP storage, saved window state). The
# `thdxg/tap` tap goes last, once nothing from it is installed.
#
# Safe to drop once every machine has applied past it; see the Brewfile,
# which no longer declares the cask.

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"

if pgrep -x Macterm >/dev/null 2>&1; then
    echo "Quitting Macterm..."
    osascript -e 'tell application "Macterm" to quit' >/dev/null 2>&1 || pkill -x Macterm
fi

if command -v brew >/dev/null 2>&1 && brew list --cask macterm &>/dev/null; then
    echo "Removing Macterm..."
    brew uninstall --cask --zap macterm
elif [ -d /Applications/Macterm.app ]; then
    rm -rf /Applications/Macterm.app
fi

defaults delete com.thdxg.macterm >/dev/null 2>&1 || true
rm -rf \
    ~/"Library/Application Support/Macterm" \
    ~/Library/Preferences/com.thdxg.macterm.plist \
    ~/Library/Caches/com.thdxg.macterm \
    ~/Library/HTTPStorages/com.thdxg.macterm \
    ~/"Library/Saved Application State/com.thdxg.macterm.savedState"

if command -v brew >/dev/null 2>&1 && brew tap | grep -qx 'thdxg/tap'; then
    brew untap thdxg/tap || true
fi
