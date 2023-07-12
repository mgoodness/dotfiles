#!/bin/bash
# shellcheck shell=bash

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"

fish=$(command -v fish || true)
if ! [ -x "$fish" ]; then
  echo "Skipping due to missing fish"
elif ! grep -q "$fish" /etc/shells; then
  echo "Updating login shell..."
  echo "$fish" | sudo tee -a /etc/shells >/dev/null
  chsh -s "$fish"
fi
