# Enforce XDG compliance
#
# References
# - Spec: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# - Support: https://wiki.archlinux.org/title/XDG_Base_Directory

# NOTE: faster than `mkdir -p` alone, since test is a builtin
function __maybe_mkdir
    test -d "$argv" || mkdir -p "$argv"
end

# Core directories
set -gx LOCAL_BIN ~/.local/bin # Non-XDG standard
__maybe_mkdir $LOCAL_BIN

set -gx XDG_CACHE_HOME ~/.cache
set -gx XDG_CONFIG_HOME ~/.config
set -gx XDG_DATA_HOME ~/.local/share
set -gx XDG_STATE_HOME ~/.local/state
set -gx --path LOCAL_BIN_DIRS $LOCAL_BIN
set -gx --path XDG_DATA_DIRS $HOMEBREW_PREFIX/share /usr/local/share /usr/share

for d in XDG_{CACHE,CONFIG,DATA,STATE}_HOME
    __maybe_mkdir $$d
end

# Homebrew
set -gx HOMEBREW_BUNDLE_FILE $XDG_CONFIG_HOME/homebrew/Brewfile
set -gx HOMEBREW_CACHE $XDG_CACHE_HOME/homebrew
set -gx HOMEBREW_LOGS $XDG_CACHE_HOME/homebrew/logs

# Deno
set -gx DENO_INSTALL_ROOT ~/.local

# Eza
set -gx EZA_CONFIG_DIR $XDG_CONFIG_HOME/eza

# gcloud
set -gx CLOUDSDK_CONFIG $XDG_CONFIG_HOME/gcloud
__maybe_mkdir $CLOUDSDK_CONFIG

# GNU utilities
set -gx GNU_BINS /usr/local/opt/gnu-{sed,tar}/libexec/gnubin

# Go
set -gx GOBIN $LOCAL_BIN
set -gx GOPATH $XDG_DATA_HOME/go

# Krew
# set -gx KREW_ROOT $XDG_CACHE_HOME/krew
fish_add_path $HOME/.krew/bin

# K8s
set -gx KUBECONFIG $XDG_DATA_HOME/kube/config.yaml
set -gx KUBECACHEDIR $XDG_CACHE_HOME/kube

# Less
set -gx LESSHISTFILE /dev/null

# Node
set -gx NODE_REPL_HISTORY /dev/null
set -gx NPM_CONFIG_CACHE $XDG_CACHE_HOME/npm
set -gx NPM_CONFIG_PREFIX ~/.local
set -gx NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc

# pip
set -gx PIP_CACHE_DIR $XDG_CACHE_HOME/pip
set -gx PIP_CONFIG_FILE $XDG_CONFIG_HOME/pip/pip.conf

# pkgx
set -gx PKGX_DIR $XDG_DATA_HOME/pkgx

# Poetry
set -gx POETRY_CACHE_DIR $XDG_CACHE_HOME/poetry
set -gx POETRY_CONFIG_DIR $XDG_CONFIG_HOME/poetry
set -gx POETRY_DATA_DIR $XDG_DATA_HOME/poetry

# psql
set -gx PSQL_HISTORY /dev/null

# Python
set -gx PYTHONSTARTUP $XDG_CONFIG_HOME/python/startup.py

# Ripgrep
set -gx RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/ripgrep.conf

# Ruby
set -gx BUNDLE_USER_CACHE $XDG_CACHE_HOME/bundle
set -gx BUNDLE_USER_CONFIG $XDG_CONFIG_HOME/bundle
set -gx BUNDLE_USER_PLUGIN $XDG_DATA_HOME/bundle
set -gx GEM_HOME $XDG_DATA_HOME/gem
set -gx GEM_SPEC_CACHE $XDG_CACHE_HOME/gem

# Rust
set -gx CARGO_HOME $XDG_DATA_HOME/cargo
set -gx CARGO_INSTALL_ROOT ~/.local
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup

# ssh
set -gx GIT_SSH_COMMAND "ssh -F $XDG_CONFIG_HOME/ssh/config"
alias ssh $GIT_SSH_COMMAND

# zsh
set -gx ZDOTDIR $XDG_CONFIG_HOME/zsh

# MANPATH
set -gxp MANPATH : # defer to $PATH

# PATH
if status is-login
    fish_add_path -g $HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin
    # fish_add_path -g $GNU_BINS
    # fish_add_path -g $KREW_ROOT
    fish_add_path -g --move --path $LOCAL_BIN_DIRS $HOMEBREW_PREFIX/{,s}bin
    set PATH (path filter -d $PATH)
end
