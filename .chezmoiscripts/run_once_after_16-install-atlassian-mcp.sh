#!/usr/bin/env bash
# shellcheck shell=bash

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

claude mcp get atlassian >/dev/null 2>&1 || claude mcp add --scope user --transport http atlassian https://mcp.atlassian.com/v1/mcp/authv2
