#!/bin/bash
# shellcheck shell=bash

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

export HOMEBREW_BUNDLE_FILE=~/.config/homebrew/Brewfile
if ! brew bundle check &>/dev/null; then
  echo "Installing Homebrew packages..."
  brew bundle install --no-lock
fi  
