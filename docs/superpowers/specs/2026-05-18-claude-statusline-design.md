# Claude Code Statusline — Fish Function

**Date:** 2026-05-18
**Status:** Approved

## Summary

Replace the existing bash statusline script with a fish function that reads live Tide prompt variables for colors and icons, keeping the statusline in automatic sync with the Tide theme config.

## Architecture

**New file:** `dot_config/fish/functions/claude-statusline.fish`

A named fish function (`claude-statusline`) that:

1. Reads JSON from stdin via `read -z input`
2. Parses each field with `printf '%s' $input | jq -r '...'`
3. Reads colors and icons from live `$tide_*` variables (available because `conf.d/tide.fish` sources unconditionally for all fish sessions, including non-interactive `fish -c`)
4. Writes the formatted line to stdout

**Settings change:** `dot_claude/private_settings.json`

```diff
- "command": "bash /Users/Michael.Goodness/.claude/statusline-command.sh"
+ "command": "fish -c claude-statusline"
```

The existing `~/.claude/statusline-command.sh` is left in place (not tracked in chezmoi) but no longer invoked.

## Field Rendering

Sections separated by two spaces. Each uses `set_color` with the corresponding Tide variable.

| Section     | Tide variable(s)                            | Format                        |
| ----------- | ------------------------------------------- | ----------------------------- |
| CWD         | `$tide_pwd_color_anchors`, `$tide_pwd_icon` | `{icon} ~/path/to/dir`        |
| Git (clean) | `$tide_git_color_branch`, `$tide_git_icon`  | `{icon} main`                 |
| Git (dirty) | `$tide_git_color_dirty`                     | `{icon} main *`               |
| Model       | `$tide_context_color_default`               | `claude-sonnet-4-6`           |
| Context %   | `$tide_cmd_duration_color`                  | `ctx:45%`                     |
| Rate limit  | `$tide_cmd_duration_color`                  | `5h:12%`                      |
| Vim mode    | `$tide_vi_mode_color_{mode}`                | `[N]` / `[I]` / `[R]` / `[V]` |

**Git truncation:** 24 chars, matching `$tide_git_truncation_length`.

**CWD:** `$HOME` prefix replaced with `~`.

**Dirty detection:** any output from `git status --porcelain` → append ` *`, color switches to `$tide_git_color_dirty`.

**Vim mode colors:** `[N]` uses `$tide_vi_mode_color_default`, `[I]` uses `$tide_vi_mode_color_insert`, `[R]` uses `$tide_vi_mode_color_replace`, `[V]` uses `$tide_vi_mode_color_visual`. Absent/empty vim mode → section omitted.

## Files Changed

| File                                               | Change         |
| -------------------------------------------------- | -------------- |
| `dot_config/fish/functions/claude-statusline.fish` | New            |
| `dot_claude/private_settings.json`                 | Update command |
