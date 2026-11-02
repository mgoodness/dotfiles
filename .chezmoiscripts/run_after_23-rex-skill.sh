#!/usr/bin/env bash
# shellcheck shell=bash

# Keeps Rex's agent skill installed for pi (~/.agents/skills/rex).
#
# The skill is a stub that Rex owns: it reads its guide from the installed
# `rex` CLI at use time, so upgrading Rex updates what agents are told and
# this repo deliberately doesn't vendor a copy. `rex skill setup` is
# idempotent ("unchanged" when current), so it runs on every apply: Rex
# Beta is installed by hand, and a run_once would be spent on the first apply
# that finds it missing.
#
# `rex` is only on PATH inside a Rex terminal, so fall back to the CLI inside
# the app's server bundle. --autostart=false keeps a plain apply from
# launching the Rex server.

if [ -n "${CI:-}" ]; then
    echo "Skipping due to \$CI"
    exit
fi

rex_bin="$(command -v rex || true)"
if [ -z "$rex_bin" ]; then
    rex_bin="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
fi
if [ ! -x "$rex_bin" ]; then
    echo "Skipping: rex not found"
    exit
fi

"$rex_bin" --autostart=false skill setup --agent pi
