status is-login || exit

# Environment
set -gx EDITOR hx

set -gx GIT_MERGE_AUTOEDIT no # accept default merge commit message
set -gx GIT_WORKSPACE ~/Code

set -gx LESS "--incsearch --ignore-case --jump-target=.5 --LONG-PROMPT --raw-control-chars --quit-if-one-screen"
set -gx LESSCHARSET utf-8
set -gx LS_COLORS $(vivid generate catppuccin-latte)
set -gx PAGER less

set -gx USE_GKE_GCLOUD_AUTH_PLUGIN True

set -gx fish_features all
set -gx fish_greeting
set -g fish_key_bindings fish_vi_key_bindings

command -q delta || set -gx GIT_PAGER $PAGER

# Daily update
# up --auto
