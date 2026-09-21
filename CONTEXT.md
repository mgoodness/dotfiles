# Dotfiles Repo Conventions

Vocabulary for concepts specific to how this repo organizes machine provisioning (chezmoi). Glossary only — mechanics live in `docs/adr/`.

## Language

### Chezmoi Machine Roles

**Chezmoi role**:
One or both of two independent boolean data flags — `mlb` and `personal` — prompted once at `chezmoi init` and persisted in that machine's own `~/.config/chezmoi/chezmoi.toml`. Not mutually exclusive: a machine can carry both roles (e.g. a company-owned machine also used for personal work). Templates and `.chezmoiignore` read these flags to decide which machine-specific Homebrew packages, secrets, git identity, and macOS defaults apply.
_Avoid_: profile, machine type, environment (chezmoi already uses "data" for the underlying mechanism — "role" names this repo's specific two flags, not chezmoi's general templating data).
