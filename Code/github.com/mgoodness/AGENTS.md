# mgoodness

Notes for personal repos under `~/Code/github.com/mgoodness/`.

## Release automation (shared GitHub App)

Personal repos share one **private** GitHub App, `mgoodness-release-please`
(Client ID `Iv23lijnZgs6R7WhJM7P`), as the first-party identity for
release-please and anything else that must push, tag, or open PRs instead of
using `GITHUB_TOKEN`. Install that App on the repo; never create a per-repo
App. Expose it in each repo as:

- repository **variable** `RELEASE_PLEASE_APP_CLIENT_ID`
- repository **secret** `RELEASE_PLEASE_APP_PRIVATE_KEY`

The App carries Contents, Issues and Pull requests — all read and write. The
shared `setup-release-please-app` tool (from dotfiles, `dot_local/bin/`)
installs any release-please App on a repo or org and sets both; repos keep a
thin `scripts/setup-release-please-app.sh` that calls it. Its `--client-id`
and `--key-file` both accept an `op://vault/item/field` reference in place of
a literal value or path — the Client ID and private key live in 1Password
under the `release-please` item (Private vault); copy the PEM file's secret
reference ("Copy Secret Reference" in the 1Password app) for `--key-file`
and nothing needs manual pasting. See the `release-please` and
`github-app-token` skills for the wiring.
