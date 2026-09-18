set -gx MISE_IGNORED_CONFIG_PATHS $XDG_DATA_HOME/chezmoi/dot_config/mise/config.toml

# Per-host GH_TOKEN/GH_HOST switching (Code/github.com, github.mlbam.net,
# emu.github.com mise.toml files) depends on mise's hook-env firing on cd, so
# activation is required, not optional — declared explicitly here rather than
# relying on the mise formula's own vendor_conf.d to auto-source it.
status is-interactive && mise activate fish | source

# No mise shims dir is added here: `activate_shims = false` in
# dot_config/mise/config.toml.tmpl keeps `mise activate` from prepending it too.
