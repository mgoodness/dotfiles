#!/usr/bin/env bash
# shellcheck shell=bash

# TODO: Rebuild bat cache on syntax & theme changes in `$(bat --config-dir)`
# Ref: https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/#run-a-script-when-the-contents-of-another-file-changes

bat cache --build
