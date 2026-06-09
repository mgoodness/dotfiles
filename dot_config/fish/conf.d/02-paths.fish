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
set -gx LOCAL_BIN ~/.local/bin
__maybe_mkdir $LOCAL_BIN

set -gx XDG_CACHE_HOME ~/.cache
set -gx XDG_CONFIG_HOME ~/.config
set -gx XDG_DATA_HOME ~/.local/share
set -gx XDG_STATE_HOME ~/.local/state
set -gx --path XDG_DATA_DIRS $HOMEBREW_PREFIX/share /usr/local/share /usr/share

for d in XDG_{CACHE,CONFIG,DATA,STATE}_HOME
    __maybe_mkdir $$d
end

# Claude
set -gx CLAUDE_CONFIG_DIR $XDG_CONFIG_HOME/claude

# Homebrew
set -gx HOMEBREW_BUNDLE_FILE $XDG_CONFIG_HOME/homebrew/Brewfile
set -gx HOMEBREW_CACHE $XDG_CACHE_HOME/homebrew
set -gx HOMEBREW_LOGS $XDG_CACHE_HOME/homebrew/logs

# gcloud
set -gx GCLOUD_SDK_DIR $HOMEBREW_PREFIX/share/google-cloud-sdk

# GNU utilities
set -gx --path GNU_BINS /usr/local/opt/{coreutils,gnu-{sed,tar}}/libexec/gnubin

# Go
set -gx GOBIN $LOCAL_BIN
set -gx GOPATH $XDG_DATA_HOME/go

# Krew
set -gx HOMEBREW_KREW_ROOT $XDG_DATA_HOME/krew
set -gx KREW_ROOT $XDG_DATA_HOME/krew

# K8s
set -gx KUBECONFIG $XDG_DATA_HOME/kube/config.yaml
set -gx KUBECACHEDIR $XDG_CACHE_HOME/kube

# Less
set -gx LESSHISTFILE /dev/null

# Node
set -gx NODE_REPL_HISTORY /dev/null
set -gx NPM_CONFIG_CACHE $XDG_CACHE_HOME/npm
set -gx NPM_CONFIG_LOGS_DIR $XDG_CACHE_HOME/npm/logs
# set -gx NPM_CONFIG_PREFIX ~/.local
set -gx NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc

# pip
set -gx PIP_CACHE_DIR $XDG_CACHE_HOME/pip
set -gx PIP_CONFIG_FILE $XDG_CONFIG_HOME/pip/pip.conf

# pkgx
set -gx PKGX_DIR $XDG_DATA_HOME/pkgx

# Poetry
set -gx POETRY_CACHE_DIR $XDG_CACHE_HOME/pypoetry
set -gx POETRY_CONFIG_DIR $XDG_CONFIG_HOME/pypoetry
set -gx POETRY_DATA_DIR $XDG_DATA_HOME/pypoetry

# PostgreSQL
set -gx PSQL_HISTORY /dev/null

# Python
set -gx PYTHONSTARTUP $XDG_CONFIG_HOME/python/startup.py

# Ripgrep
set -gx RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/config

# Ruby
set -gx BUNDLE_USER_CACHE $XDG_CACHE_HOME/bundle
set -gx BUNDLE_USER_CONFIG $XDG_CONFIG_HOME/bundle/config
set -gx BUNDLE_USER_PLUGIN $XDG_DATA_HOME/bundle

set -gx GEM_HOME $XDG_DATA_HOME/gem
set -gx GEM_SPEC_CACHE $XDG_CACHE_HOME/gem

# Rust
set -gx CARGO_HOME $XDG_DATA_HOME/cargo
set -gx CARGO_INSTALL_ROOT ~/.local
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup

# zsh
set -gx ZDOTDIR $XDG_CONFIG_HOME/zsh

# MANPATH
set -gxp MANPATH : # defer to $PATH

# PATH
if status is-login
    fish_add_path -g --move --path $HOMEBREW_PREFIX/{,s}bin
    fish_add_path -g $KREW_ROOT/bin
    fish_add_path -g $GCLOUD_SDK_DIR/bin
    fish_add_path -g $HOMEBREW_PREFIX/opt/ruby/bin
    fish_add_path -g $GEM_HOME/bin
    fish_add_path -g $LOCAL_BIN
    set PATH (path filter -d $PATH)
end
