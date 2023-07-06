#!/bin/bash
# shellcheck shell=bash

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"

shell=$(command -v fish)
if ! grep -q "$shell" /etc/shells; then
  echo "Updating login shell..."
  echo "$shell" | sudo tee -a /etc/shells
  chsh -s "$shell"
fi
