#!/usr/bin/env bash
# shellcheck shell=bash

# One-time removal of the Anthropic OAuth credential that
# @gotgenes/pi-anthropic-auth existed to make workable. That extension is
# retired (see .chezmoidata/pi-packages.toml), and nothing here selects Pi's
# `anthropic` provider any more — the personal profile bills opencode-go and
# the corporate hosts bill github-copilot — so the leftover Claude Pro/Max
# token is just an unused subscription credential sitting in a plaintext
# file. No backup copy is written for the same reason: it would only
# multiply the secret. The token can be recreated with `/login anthropic`.
#
# Only OAuth entries are touched. An `apiKey` entry is a deliberate billing
# choice (pay-per-token against Anthropic), not the leftover this removes.
# A machine whose settings still name `anthropic` as its default provider is
# left alone too: pruning there would change which model Pi starts with,
# and that is a decision for a human, not an apply.
#
# Safe to drop once every machine has applied past it; see the comment above
# [[retiredPiPackages]] in .chezmoidata/pi-packages.toml.

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

auth_file="${HOME}/.pi/agent/auth.json"
if [ ! -f "$auth_file" ]; then
    exit
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Skipping: jq not found"
    exit
fi

if [ "$(jq -r '.anthropic.type // empty' "$auth_file" 2>/dev/null)" != "oauth" ]; then
    exit
fi

settings_file="${HOME}/.pi/agent/settings.json"
if [ -f "$settings_file" ] && [ "$(jq -r '.defaultProvider // empty' "$settings_file" 2>/dev/null)" = "anthropic" ]; then
    echo "Keeping the Anthropic OAuth credential: settings.json still defaults to provider anthropic"
    exit
fi

echo "Removing the Anthropic OAuth credential from ~/.pi/agent/auth.json..."
pruned_file="$(jq 'del(.anthropic)' "$auth_file")" || {
    echo "WARNING: could not rewrite auth.json; leaving it untouched" >&2
    exit 1
}
if ! printf '%s\n' "$pruned_file" | jq -e 'has("anthropic") | not' >/dev/null; then
    echo "WARNING: refusing to write auth.json without the anthropic key removed" >&2
    exit 1
fi

tmp_file="$(mktemp "${auth_file}.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT
printf '%s\n' "$pruned_file" >"$tmp_file"
chmod 600 "$tmp_file"
mv "$tmp_file" "$auth_file"
