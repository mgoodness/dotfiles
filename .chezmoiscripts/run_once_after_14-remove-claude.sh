#!/usr/bin/env bash
# shellcheck shell=bash

# One-time removal of Claude, its embedded Claude Code feature, and
# ClaudeBar. Mirrors the manual cleanup done on the first machine this ran
# on: uninstalling the Homebrew cask zaps Claude's own app-support/cache/
# log/preference files (which also holds Claude Code's CLI cache dirs,
# since that feature lives inside the Claude.app bundle's data), but misses
# a couple of leftovers that aren't covered by either cask's `zap` stanza:
# Claude Code's own node-cli cache dir, and ClaudeBar's app-support/cache/
# preference files (orphaned because ClaudeBar was never Homebrew-managed
# on the source machine).
#
# Safe to drop once every machine has applied past it; see Brewfile and
# run_onchange_after_20-macos.sh.tmpl, which no longer reference Claude.

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"

if command -v brew >/dev/null 2>&1 && brew list --cask claude &>/dev/null; then
    echo "Removing Claude (and its Claude Code data)..."
    brew uninstall --cask --zap claude
fi

rm -rf ~/"Library/Application Support/claude-cli-nodejs"

if pgrep -x ClaudeBar >/dev/null 2>&1; then
    pkill -x ClaudeBar
fi
if command -v brew >/dev/null 2>&1 && brew list --cask claudebar &>/dev/null; then
    echo "Removing ClaudeBar..."
    brew uninstall --cask --zap claudebar
elif [ -d /Applications/ClaudeBar.app ]; then
    rm -rf /Applications/ClaudeBar.app
fi
rm -rf \
    ~/"Library/Application Support/ClaudeBar" \
    ~/Library/Caches/ClaudeBar \
    ~/Library/Caches/com.tddworks.claudebar \
    ~/Library/HTTPStorages/com.tddworks.claudebar \
    ~/Library/HTTPStorages/com.tddworks.claudebar.binarycookies \
    ~/Library/Logs/ClaudeBar \
    ~/Library/Preferences/ClaudeBar.plist \
    ~/Library/Preferences/com.tddworks.claudebar.plist
