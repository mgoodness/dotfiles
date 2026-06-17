#!/usr/bin/env bash
# shellcheck shell=bash

# Install worktrunk's fish shell integration (functions/wt.fish + completions).
# Idempotent; needs worktrunk from Homebrew (run_once_after_10-homebrew.sh).

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"
if ! command -v wt >/dev/null 2>&1; then
    echo "Skipping: wt not found"
    exit
fi

wt config shell install fish -y
