# mlb-systems

Notes for repos under `~/Code/emu.github.com/mlb-systems/`.

## Release automation

`mlb-systems` repos use the org-owned App `mlb-systems-automation`:
`vars.AUTOMATION_APP_CLIENT_ID` and `secrets.AUTOMATION_APP_PRIVATE_KEY`, both
provided by the org. An org owner installs it per repo (org Settings → GitHub
Apps → `mlb-systems-automation` → Configure), so `setup-release-please-app`
does not apply there. Scope each mint with `permission-*`, and keep the App out
of every ruleset's bypass list: its private key is an org secret readable by any
writer's workflow. `mlb-renovate` is the Renovate-only App behind the shared
`mlb-systems/renovate` workflow; use it for nothing else.

## Runners

Set `runs-on: mlb-systems-ghec` on every job (and `runner: mlb-systems-ghec` on
the shared Renovate workflow); declare the label under
`self-hosted-runner.labels` in `.github/actionlint.yaml` so actionlint accepts
it.
