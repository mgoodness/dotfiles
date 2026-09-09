#!/usr/bin/env bash
# shellcheck shell=bash

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

# kit-fff-enforcer: blocks kit's built-in grep/find core tools (and shell
# invocations of grep/find) in favor of the fff MCP tools, inside git work
# trees. See https://github.com/mgoodness/kit-fff-enforcer.
#
# Installed once per machine, like the sibling fff MCP registration script;
# run `kit install -u github.com/mgoodness/kit-fff-enforcer` by hand to pull
# updates.
manifest="$HOME/.local/share/kit/git/packages.json"
if [ ! -f "$manifest" ] || ! grep -q 'github.com/mgoodness/kit-fff-enforcer' "$manifest"; then
    kit install github.com/mgoodness/kit-fff-enforcer --all >/dev/null 2>&1
fi
