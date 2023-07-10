status is-login || exit

# Environment
set -gx BAT_THEME base16-256
set -gx EDITOR hx
set -gx FZF_DEFAULT_OPTS --ansi --color=16 --cycle --height=80% --layout=reverse --marker="*" --preview-window=wrap
set -gx GIT_MERGE_AUTOEDIT no # accept default merge commit message
set -gx GIT_WORKSPACE ~/Code
set -gx LESS --incsearch --ignore-case --jump-target=.5 --LONG-PROMPT --raw-control-chars --quit-if-one-screen
set -gx LESSCHARSET utf-8
set -gx PAGER less
set -gx USE_GKE_GCLOUD_AUTH_PLUGIN True

set -Uq fish_features || set -U fish_features all
set -gx fzf_fd_opts --hidden
set -gx man_bold --bold $fish_color_command
set -gx man_standout --reverse $fish_color_search_match
set -gx man_underline --underline $fish_color_param

command -q delta || set -gx GIT_PAGER $PAGER

# Daily update
up --auto
