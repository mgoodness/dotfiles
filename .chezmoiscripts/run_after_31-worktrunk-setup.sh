#!/usr/bin/env bash
# shellcheck shell=bash

# Worktrunk's user-level extras: the fish shell integration (functions/wt.fish
# + completions) and the Pi activity-tracking extension
# (extensions/worktrunk.ts). Runs every apply — both `wt config shell install`
# and `wt config plugins install` are content-aware and self-healing (each
# rewrites only when the installed copy differs and prints "already
# configured"/"already installed" otherwise), so this keeps pace with a
# Homebrew `wt` upgrade that bumps either bundled file. There is no --quiet
# flag, so `wt_quiet` below swallows the per-target no-op lines and only emits
# output when something actually changed.

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"
if ! command -v wt >/dev/null 2>&1; then
    echo "Skipping: wt not found"
    exit
fi

wt_quiet() {
    local output
    if ! output="$("$@" 2>&1)"; then
        printf '%s\n' "$output" >&2
        return 1
    fi
    if [ -n "$output" ]; then
        printf '%s\n' "$output" | grep -viE 'already (configured|installed)' || true
    fi
}

wt_quiet wt config shell install fish -y
wt_quiet wt config plugins pi install -y
