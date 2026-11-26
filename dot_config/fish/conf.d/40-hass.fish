status is-interactive || status is-login || return

# hass-cli: the Home Assistant CLI, for the registry work the MCP server has no
# tools for (`entity delete`, `integration delete`). Personal machines only — this
# file and HASS_TOKEN (the personal fnox branch) are gated on .personal.
#
# Not installed by Homebrew: its 1.0.0 bottle runs on python@3.15, where every
# WebSocket command fails with "There is no current event loop in thread
# 'MainThread'" (asyncio stopped creating a loop implicitly in 3.14; upstream #433,
# fix PR #457 merged but unreleased, PyPI still 1.0.0). The REST subcommands
# (`config release`, `integration list`, `integration delete`) do work under the
# bottle. uvx pins the interpreter instead:
#   uvx --python 3.13 --from homeassistant-cli hass-cli entity delete <id> --confirm
#   uvx --python 3.13 --from homeassistant-cli hass-cli integration list
# Re-add `brew "homeassistant-cli"` to Brewfile.personal once a release has #457.
#
# The Cloud remote-UI host rather than home.opsgoodness.net, for the same reason
# modify_mcp.json uses it: it resolves anywhere and needs no LAN access.
set -gx HASS_SERVER https://nlnxn14gitl4kd5tloexvihlfzxnewdb.ui.nabu.casa
