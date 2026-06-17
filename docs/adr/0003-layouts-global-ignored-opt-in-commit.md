# Layouts are global-ignored, committed opt-in

Muxy Layout files (`.muxy/layouts/`) are excluded globally through git's `core.excludesFile` rather than committed per-repo — even though Muxy's own design expects them checked in alongside the project. The canonical set lives in chezmoi at `~/.config/muxy/layouts/` and is symlinked into each Worktree's `.muxy/layouts/` by the worktrunk post-start hook.

This keeps Muxy-specific files out of shared corporate repos by default (no PR noise for teammates who don't use Muxy) while remaining fully reproducible from dotfiles. Sharing a Layout with a team is a deliberate `git add -f`.

## Consequences

- A single source of truth in dotfiles; edits propagate to every Worktree via the symlink.
- A repo that needs bespoke Layouts replaces the symlink with a real, force-added directory.
- The `core.excludesFile` rule also hides `.muxy/` in repos where a team _did_ adopt Muxy — accepted trade-off.
