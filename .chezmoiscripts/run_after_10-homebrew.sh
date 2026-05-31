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
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Installing Homebrew packages..."
export HOMEBREW_BUNDLE_FILE=~/.config/homebrew/Brewfile
if ! brew bundle check &>/dev/null; then
    brew bundle install
fi
