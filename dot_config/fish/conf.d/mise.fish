set -gx MISE_IGNORED_CONFIG_PATHS $XDG_DATA_HOME/chezmoi/dot_config/mise/config.toml

# Per-host GH_TOKEN/GH_HOST switching (Code/github.com, github.mlbam.net,
# emu.github.com mise.toml files) depends on mise's hook-env firing on cd, so
# activation is required, not optional — declared explicitly here rather than
# relying on the mise formula's own vendor_conf.d to auto-source it.
status is-interactive && mise activate fish | source

# mise shims on PATH so mise-managed tool versions (flutter, dart, etc.)
# resolve without needing `mise exec --`.
fish_add_path -g $HOME/.local/share/mise/shims
