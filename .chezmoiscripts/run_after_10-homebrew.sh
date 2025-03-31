#!/bin/bash
# shellcheck shell=bash

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export HOMEBREW_BUNDLE_FILE=~/.config/homebrew/Brewfile
if ! brew bundle check &>/dev/null; then
  echo "Installing Homebrew packages..."
  brew bundle install
fi
