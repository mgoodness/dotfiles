#!/usr/bin/env bash
# shellcheck shell=bash

# One-time removal of lazygit and Tailscale, both dropped from the Brewfile.
#
# lazygit was a Homebrew formula, so `brew uninstall` is the whole story.
# Tailscale came from the Mac App Store (`mas`), so there is no cask to zap:
# this deletes the app, its pkg receipt, the "Tailscale" VPN network service
# and the sandbox leftovers listed in Tailscale's macOS (App Store) uninstall
# docs. Their keychain items (tailscale-machinekey, tailscale-logdata,
# tailscale-preferences) are deliberately left behind: dropping them needs a
# keychain authorization prompt, and nothing reads them once the app is gone.
#
# Safe to drop once every machine has applied past it; see Brewfile,
# 02-paths.fish and dot_p10k.zsh, which no longer reference either.

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

export PATH="/opt/homebrew/bin:/usr/local/bin${PATH+:$PATH}"

if command -v brew >/dev/null 2>&1 && brew list --formula lazygit &>/dev/null; then
    echo "Removing lazygit..."
    brew uninstall lazygit
fi

if pgrep -x Tailscale >/dev/null 2>&1; then
    echo "Quitting Tailscale..."
    pkill -x Tailscale
fi

if [ -d /Applications/Tailscale.app ]; then
    echo "Removing Tailscale..."
    sudo rm -rf /Applications/Tailscale.app
fi

# The app registers itself as a VPN network service, which survives deleting
# the app itself.
if networksetup -listallnetworkservices 2>/dev/null | grep -qE '^\*?Tailscale$'; then
    echo "Removing the Tailscale VPN network service..."
    sudo networksetup -removenetworkservice Tailscale
fi

if pkgutil --pkgs 2>/dev/null | grep -qx io.tailscale.ipn.macos; then
    echo "Forgetting the Tailscale pkg receipt..."
    sudo pkgutil --forget io.tailscale.ipn.macos
fi

rm -rf \
    ~/Library/Application\ Scripts/*.io.tailscale.ipn.macos \
    ~/Library/Application\ Scripts/io.tailscale.ipn.macos \
    ~/Library/Application\ Scripts/io.tailscale.ipn.macos.login-item-helper \
    ~/Library/Application\ Scripts/io.tailscale.ipn.macos.share-extension \
    ~/Library/Caches/io.tailscale.ipn.macos \
    ~/Library/Containers/io.tailscale.ipn.macos \
    ~/Library/Containers/io.tailscale.ipn.macos.login-item-helper \
    ~/Library/Containers/io.tailscale.ipn.macos.network-extension \
    ~/Library/Containers/io.tailscale.ipn.macos.share-extension \
    ~/Library/Containers/Tailscale \
    ~/Library/Group\ Containers/*.io.tailscale.ipn.macos \
    ~/Library/HTTPStorages/io.tailscale.ipn.macos \
    ~/Library/Preferences/io.tailscale.ipn.macos.plist \
    ~/Library/Tailscale
