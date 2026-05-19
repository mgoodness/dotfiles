function claude-statusline
    read -z input

    set -l git_dir (printf '%s' $input | jq -r '.workspace.current_dir // .cwd // empty')
    test -z "$git_dir" && set git_dir $PWD
    set -l cwd (string replace -- $HOME '~' $git_dir)

    set -l git_branch (git -C $git_dir --no-optional-locks branch --show-current 2>/dev/null)
    if test -n "$git_branch"
        set -l trunc_len 24
        set -q tide_git_truncation_length; and set trunc_len $tide_git_truncation_length
        if test (string length -- $git_branch) -gt $trunc_len
            set git_branch (string sub -l $trunc_len -- $git_branch)...
        end
        set -l porcelain (git -C $git_dir --no-optional-locks status --porcelain 2>/dev/null | head -1)
        set -l git_is_dirty ""
        set -l git_dirty_marker ""
        if test -n "$porcelain"
            set git_is_dirty 1
            set git_dirty_marker " *"
        end
    end

    set -l model (printf '%s' $input | jq -r '.model.display_name // empty')
    set -l used_pct (printf '%s' $input | jq -r '.context_window.used_percentage // empty')
    set -l five_pct (printf '%s' $input | jq -r '.rate_limits.five_hour.used_percentage // empty')
    set -l vim_mode (printf '%s' $input | jq -r '.vim.mode // empty')

    set -q tide_pwd_color_anchors[1]; or set -l tide_pwd_color_anchors normal
    set -q tide_git_color_branch[1]; or set -l tide_git_color_branch normal
    set -q tide_git_color_dirty[1]; or set -l tide_git_color_dirty normal
    set -q tide_context_color_default[1]; or set -l tide_context_color_default normal
    set -q tide_cmd_duration_color[1]; or set -l tide_cmd_duration_color normal
    set -q tide_vi_mode_color_default[1]; or set -l tide_vi_mode_color_default normal
    set -q tide_vi_mode_color_insert[1]; or set -l tide_vi_mode_color_insert normal
    set -q tide_vi_mode_color_replace[1]; or set -l tide_vi_mode_color_replace normal
    set -q tide_vi_mode_color_visual[1]; or set -l tide_vi_mode_color_visual normal

    set_color $tide_pwd_color_anchors
    printf '%s %s' $tide_pwd_icon $cwd
    set_color normal

    if test -n "$git_branch"
        printf '  '
        if test -n "$git_is_dirty"
            set_color $tide_git_color_dirty
        else
            set_color $tide_git_color_branch
        end
        printf '%s %s%s' $tide_git_icon $git_branch $git_dirty_marker
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
