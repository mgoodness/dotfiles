# Machine roles as two independent booleans, split strategy chosen per file shape

This repo is applied to two Macs with different needs: a company-owned MacBook Pro used for both MLB work and personal use, and a personal-only Mac mini. We modeled this as two independent boolean chezmoi data flags, `mlb` and `personal` (prompted once at `chezmoi init`), rather than a single `role` enum — a machine can carry both, and a strict either/or enum can't express that without a third "both" value that just re-invents two booleans anyway.

Which of three splitting mechanisms applies is decided per file by its shape, not applied uniformly:

- **Templated `.chezmoiignore`** (whole file/directory exclusion) for content that's cleanly single-role, e.g. `Code/emu.github.com/**` and `Code/github.mlbam.net/**`, excluded entirely when `mlb` is false.
- **Split-and-merge sibling files** (shared + `.mlb` + `.personal`, combined at apply/refresh time) for flat lists mixing both roles, e.g. the Homebrew `Brewfile` and `dot_config/fish/secrets.yaml` — splitting avoids `{{ if }}` noise across dozens of otherwise-identical-looking lines.
- **Inline `{{ if }}` conditionals in one `.tmpl`** for scripts that are mostly shared with only a few divergent lines, e.g. `run_onchange_after_20-macos.sh` (Dock layout differs by role; most `defaults write` calls don't) — splitting this one into three scripts would triplicate the shared bulk of it.

## Consequences

- Adding a new role-specific setting means first asking "which shape is this" and picking the matching mechanism, rather than always reaching for the same pattern.
- The `mlb` / `personal` flag names intentionally reuse herdr's existing `MLB` / `Personal` **Workspace label** convention (see `CONTEXT.md`) rather than generic `work` / `personal` — consistent vocabulary across the repo's two contexts (herdr workflow, chezmoi provisioning).
