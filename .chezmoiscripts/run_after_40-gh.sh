#!/bin/bash
# shellcheck shell=bash

# Install GitHub CLI extensions

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

gh extension install seachicken/gh-poi
