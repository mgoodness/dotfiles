#!/usr/bin/env bash
# shellcheck shell=bash

# One-time bootstrap: install every skill under mattpocock/skills'
# skills/engineering and skills/productivity directories, for both
# claude-code and pi. Runs once per machine, at run time (not
# template-render time), so it doesn't add a network dependency to every
# `chezmoi apply`. Keeping this set current afterward — picking up skills
# mattpocock adds, dropping ones removed — is the `up skills` fish
# function's job, not this script's; see dot_config/fish/functions/up.fish.

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

if ! command -v gh &>/dev/null; then
    echo "Skipping: gh not found"
    exit
fi

if ! command -v npx &>/dev/null; then
    echo "Skipping: npx not found"
    exit
fi

# Pinned so a `skills` release doesn't silently change apply behavior on one
# machine before another. Bump deliberately; see `up skills` for the fish
# side of this same pin.
skills_version="1.7.0"

# `skills add` is chatty on every call even on success; swallow that but
# still surface a real failure. See install-agent-skills.sh.tmpl for detail
# on why --json is load-bearing here, not just for parsing.
skills_add() {
    local out
    if ! out=$(npx --yes "skills@${skills_version}" add "$@" --json 2>&1); then
        printf '%s\n' "$out" >&2
        return 1
    fi
}

repo="mattpocock/skills"
agents=(claude-code pi)

names=$(
    for dir in skills/engineering skills/productivity; do
        gh api "repos/${repo}/contents/${dir}" --jq '.[] | select(.type == "dir") | .name' 2>/dev/null
    done | sort -u
)

if [ -z "$names" ]; then
    echo "Skipping: could not discover $repo skill list"
    exit
fi

mapfile -t name_array <<<"$names"
skills_add "$repo" --skill "${name_array[@]}" --agent "${agents[@]}" -g -y
