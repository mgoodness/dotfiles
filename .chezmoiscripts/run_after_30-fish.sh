#!/usr/bin/env bash
# shellcheck shell=bash

# Update default login shell

fish=$(command -v fish || true)
if ! [ -x "$fish" ]; then
    echo "Skipping due to missing fish"
    exit
fi

if [ "$(uname)" = Darwin ]; then
    shell=$(dscl . -read ~/ UserShell | sed 's/UserShell: //')
fi
if [ "$shell" = "$fish" ]; then
    echo "Login shell is already $shell"
    exit
fi

echo "Updating login shell: $shell -> $fish"
grep -q "$fish" /etc/shells || echo "$fish" | sudo tee -a /etc/shells >/dev/null
chsh -s "$fish"
