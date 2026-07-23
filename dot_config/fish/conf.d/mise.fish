set -gx MISE_IGNORED_CONFIG_PATHS $XDG_DATA_HOME/chezmoi/dot_config/mise/config.toml

# mise shims on PATH so mise-managed tool versions (flutter, dart, etc.)
# resolve without needing `mise exec --`.
fish_add_path -g $HOME/.local/share/mise/shims
