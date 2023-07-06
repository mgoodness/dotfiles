# Enforce XDG compliance
#
# References
# - Spec: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
# - Support: https://wiki.archlinux.org/title/XDG_Base_Directory

# NOTE: faster than `mkdir -p` alone, since test is a builtin
function __maybe_mkdir
    test -d "$argv" || mkdir -p "$argv"
end

set -gx LOCAL_BIN ~/.local/bin # Non-standard
__maybe_mkdir $LOCAL_BIN

# Core directories
set -gx XDG_CACHE_HOME ~/.cache
set -gx XDG_CONFIG_HOME ~/.config
set -gx XDG_DATA_HOME ~/.local/share
set -gx XDG_STATE_HOME ~/.local/state

for d in XDG_{CACHE,CONFIG,DATA,STATE}_HOME
    __maybe_mkdir $$d
end

# Deno
set -gx DENO_INSTALL_ROOT $LOCAL_BIN/..

# GCP
set -gx CLOUDSDK_CONFIG $XDG_CONFIG_HOME/gcloud
__maybe_mkdir $CLOUDSDK_CONFIG

# Gnu Utilities
set -gx GNU_BINS /usr/local/opt/gnu-{sed,tar}/libexec/gnubin

# GnuPG
set -gx GNUPGHOME $XDG_DATA_HOME/gnupg
__maybe_mkdir $GNUPGHOME

# Go
set -gx GOBIN $LOCAL_BIN
set -gx GOPATH $XDG_DATA_HOME/go

# Homebrew
set -gx HOMEBREW_BUNDLE_FILE $XDG_CONFIG_HOME/homebrew/Brewfile

# K8s
set -gx KUBECONFIG $XDG_DATA_HOME/kube/config.yaml
set -gx KUBECACHEDIR $XDG_CACHE_HOME/kube

# Krew
set -gx KREW_ROOT $XDG_CACHE_HOME/krew

# Less
set -gx LESSHISTFILE /dev/null

# Node
set -gx NODE_REPL_HISTORY /dev/null
set -gx NO_UPDATE_NOTIFIER 1 # used by npm: https://github.com/yeoman/update-notifier/issues/180
set -gx NPM_CONFIG_CACHE $XDG_CACHE_HOME/npm
set -gx NPM_CONFIG_DEVDIR $XDG_DATA_HOME/node-gyp
set -gx NPM_CONFIG_INIT_MODULE $XDG_CONFIG_HOME/npm/config/npm-init.js
set -gx NPM_CONFIG_PREFIX $XDG_DATA_HOME/npm
set -gx NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc
__maybe_mkdir $NPM_CONFIG_PREFIX/bin
__maybe_mkdir $NPM_CONFIG_PREFIX/lib

# Python
# set -gx PIPX_BIN_DIR=$LOCAL_BIN
set -gx PIPX_HOME $XDG_DATA_HOME/pipx
# set -gx PYENV_ROOT $XDG_DATA_HOME/pyenv
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
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup
__maybe_mkdir $CARGO_HOME/bin

# SSH
set -gx GIT_SSH_COMMAND "ssh -F $XDG_CONFIG_HOME/ssh/config"
alias ssh $GIT_SSH_COMMAND

# VS Code: https://github.com/microsoft/vscode/issues/3884

# Zsh
set -gx ZDOTDIR $XDG_CONFIG_HOME/zsh

# PATH
if status is-login
    fish_add_path -g $HOMEBREW_PREFIX/{,s}bin
    fish_add_path -g $HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin
    fish_add_path -g $GNU_BINS
    fish_add_path -g $LOCAL_BIN
    fish_add_path -g $NPM_CONFIG_PREFIX/bin
    fish_add_path -g $CARGO_HOME/bin
    fish_add_path -g $KREW_ROOT/bin
end
