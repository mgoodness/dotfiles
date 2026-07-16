#!/usr/bin/env bash
# shellcheck shell=bash

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

claude mcp get fff >/dev/null 2>&1 || claude mcp add -s user fff -- /opt/homebrew/bin/fff-mcp
