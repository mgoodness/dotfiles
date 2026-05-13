#!/bin/bash
# shellcheck shell=bash

# Install GitHub CLI extensions

if [ -n "${CI:-}" ]; then
    debugw "Skipping due to \$CI"
    return
fi

gh extension install github/gh-copilot
gh extension install seachicken/gh-poi
