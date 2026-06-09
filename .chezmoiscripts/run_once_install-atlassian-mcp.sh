#!/usr/bin/env bash
# shellcheck shell=bash

if [ -n "${CI:-}" ]; then
    echo "Skipping due to $CI"
    exit
fi

claude mcp get atlassian >/dev/null 2>&1 || claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse --scope user
