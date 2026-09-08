#!/usr/bin/env bash
# shellcheck shell=bash

# Install Homebrew and packages

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# mise-managed project directories (see Code/*/mise.toml) shell out to `op`
# for secrets as soon as any shell activates mise there; install it first so
# a brand-new machine's first shell/cd can't race the rest of the bundle.
if ! command -v op >/dev/null 2>&1; then
    brew install --cask 1password-cli
fi

echo "Installing Homebrew packages..."
BUNDLE_FILE="$(mktemp)"
trap 'rm -f "$BUNDLE_FILE"' EXIT
cat ~/.config/homebrew/Brewfile ~/.config/homebrew/Brewfile.mlb ~/.config/homebrew/Brewfile.personal 2>/dev/null >"$BUNDLE_FILE"

export HOMEBREW_BUNDLE_FILE="$BUNDLE_FILE"
if ! brew bundle check &>/dev/null; then
    brew bundle install
fi
