# Claude Code Statusline Fish Function — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `~/.claude/statusline-command.sh` with a fish function that reads live Tide variables for automatic color/icon sync.

**Architecture:** Single fish function `claude-statusline` in `dot_config/fish/functions/`. Reads JSON from stdin via `read -z`, parses fields with `jq`, applies colors via `set_color $tide_*` (available because `conf.d/tide.fish` runs unconditionally for all fish sessions), and writes a formatted line. `dot_claude/private_settings.json` updated to invoke it as `fish -c claude-statusline`.

**Tech Stack:** Fish shell, jq, git

---

## Files

| File                                               | Change |
| -------------------------------------------------- | ------ |
| `dot_config/fish/functions/claude-statusline.fish` | Create |
| `dot_claude/private_settings.json`                 | Modify |

---

## Task 1: Create the `claude-statusline` fish function

**Files:**

- Create: `dot_config/fish/functions/claude-statusline.fish`

- [ ] **Step 1: Confirm function is absent**

```bash
fish -c claude-statusline <<< '{}' 2>&1
```

Expected: `fish: Unknown command: claude-statusline`

- [ ] **Step 2: Create the function**

Create `dot_config/fish/functions/claude-statusline.fish`:

```fish
function claude-statusline
    read -z input

    set -l git_dir (printf '%s' $input | jq -r '.workspace.current_dir // .cwd // empty')
    set -l cwd (string replace -- $HOME '~' $git_dir)

    set -l git_branch (git -C $git_dir --no-optional-locks branch --show-current 2>/dev/null)
    set -l git_dirty ""
    if test -n "$git_branch"
        if test (string length -- $git_branch) -gt $tide_git_truncation_length
            set git_branch (string sub -l $tide_git_truncation_length -- $git_branch)...
        end
        set -l porcelain (git -C $git_dir --no-optional-locks status --porcelain 2>/dev/null | head -1)
        test -n "$porcelain" && set git_dirty " *"
    end

    set -l model (printf '%s' $input | jq -r '.model.display_name // empty')
    set -l used_pct (printf '%s' $input | jq -r '.context_window.used_percentage // empty')
    set -l five_pct (printf '%s' $input | jq -r '.rate_limits.five_hour.used_percentage // empty')
    set -l vim_mode (printf '%s' $input | jq -r '.vim.mode // empty')

    set_color $tide_pwd_color_anchors
    printf '%s %s' $tide_pwd_icon $cwd
    set_color normal

    if test -n "$git_branch"
        printf '  '
        if test -n "$git_dirty"
            set_color $tide_git_color_dirty
        else
            set_color $tide_git_color_branch
        end
        printf '%s %s%s' $tide_git_icon $git_branch $git_dirty
        set_color normal
    end

    if test -n "$model"
        printf '  '
        set_color $tide_context_color_default
        printf '%s' $model
        set_color normal
    end

    if test -n "$used_pct"
        set_color $tide_cmd_duration_color
        printf '  ctx:%.0f%%' $used_pct
        set_color normal
    end

    if test -n "$five_pct"
        set_color $tide_cmd_duration_color
        printf '  5h:%.0f%%' $five_pct
        set_color normal
    end

    if test -n "$vim_mode"
        printf '  '
        switch $vim_mode
            case N
                set_color $tide_vi_mode_color_default
            case I
                set_color $tide_vi_mode_color_insert
            case R
                set_color $tide_vi_mode_color_replace
            case V
                set_color $tide_vi_mode_color_visual
        end
        printf '[%s]' $vim_mode
        set_color normal
    end

    printf '\n'
end
```

- [ ] **Step 3: Apply and run smoke tests**

Install to `~/.config/fish/functions/`:

```bash
chezmoi apply ~/.config/fish/functions/claude-statusline.fish
```

**Test 1 — non-git directory, all fields present (ANSI stripped):**

```bash
printf '%s' '{"workspace":{"current_dir":"/tmp"},"model":{"display_name":"test-model"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":10}},"vim":{"mode":"N"}}' \
  | fish -c claude-statusline \
  | string replace -ra '\x1b\[[0-9;]*m' ''
```

Expected output contains: `/tmp`, `test-model`, `ctx:50%`, `5h:10%`, `[N]`. No git section (not a repo).

**Test 2 — git repo, check branch and dirty indicator:**

```bash
printf '%s' "{\"workspace\":{\"current_dir\":\"$PWD\"},\"model\":{\"display_name\":\"claude-sonnet-4-6\"},\"context_window\":{\"used_percentage\":45},\"rate_limits\":{\"five_hour\":{\"used_percentage\":12}},\"vim\":{\"mode\":\"I\"}}" \
  | fish -c claude-statusline \
  | string replace -ra '\x1b\[[0-9;]*m' ''
```

Expected output contains: `~/.local/share/chezmoi`, `main`, `claude-sonnet-4-6`, `ctx:45%`, `5h:12%`, `[I]`.

If the working tree has uncommitted changes, branch shows ` *` suffix.

- [ ] **Step 4: Commit**

```bash
git add dot_config/fish/functions/claude-statusline.fish
git commit -m "feat(fish): add claude-statusline function with tide variable support"
```

---

## Task 2: Update settings to invoke the fish function

**Files:**

- Modify: `dot_claude/private_settings.json`

- [ ] **Step 1: Update the statusline command**

Edit `dot_claude/private_settings.json`. Change the `statusLine.command` value:

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true
  },
  "extraKnownMarketplaces": {},
  "theme": "auto",
  "statusLine": {
    "type": "command",
    "command": "fish -c claude-statusline"
  }
}
```

- [ ] **Step 2: Apply and verify**

```bash
chezmoi apply ~/.claude/private_settings.json
```

Reload Claude Code. The statusline should show CWD, git branch (with `*` when dirty), model, `ctx:%`, `5h:%`, and vim mode. If blank, debug with:

```bash
printf '%s' '{"workspace":{"current_dir":"/tmp"},"model":{"display_name":"claude-sonnet-4-6"}}' \
  | fish -c claude-statusline
```

- [ ] **Step 3: Commit**

```bash
git add dot_claude/private_settings.json
git commit -m "chore(claude): switch statusline to fish function"
```
