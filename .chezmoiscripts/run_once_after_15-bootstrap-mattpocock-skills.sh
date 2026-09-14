#!/usr/bin/env bash
# shellcheck shell=bash

# One-time bootstrap: install every skill under mattpocock/skills'
# skills/engineering and skills/productivity directories, for both
# claude-code and universal agents. Runs once per machine, at run time
# (not template-render time), so it doesn't add a network dependency to
# every `chezmoi apply`. Keeping this set current afterward — picking up
# skills mattpocock adds, dropping ones removed — is the `up skills` fish
# function's job, not this script's; see dot_config/fish/functions/up.fish.

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

if ! command -v gh &>/dev/null; then
    echo "Skipping: gh not found"
    exit
fi

# gh skill install is chatty on every call even on success; swallow that but
# still surface a real failure. See install-agent-skills.sh.tmpl for detail.
gh_skill_install() {
    local err
    if ! err=$(gh skill install "$@" 2>&1 1>/dev/null); then
        printf '%s\n' "$err" >&2
        return 1
    fi
}

repo="mattpocock/skills"
agents=(claude-code universal)

names=$(
    for dir in skills/engineering skills/productivity; do
        gh api "repos/${repo}/contents/${dir}" --jq '.[] | select(.type == "dir") | .name' 2>/dev/null
    done | sort -u
)

if [ -z "$names" ]; then
    echo "Skipping: could not discover $repo skill list"
    exit
fi

while IFS= read -r name; do
    for agent in "${agents[@]}"; do
        gh_skill_install "$repo" "$name" --agent "$agent" --scope user -f
    done
done <<<"$names"
