# Renovate: the other branch of steps 3 and 4

Use Renovate where an org ships a shared Renovate workflow (in `mlb-systems`, the reusable workflow `mlb-systems/renovate`), or where the repo needs private registries, Helm, or custom managers that Dependabot cannot reach. Run one updater per ecosystem.

## Config

| Dependabot                               | Renovate                                                                                                                                                                                                                                             |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cooldown.default-days: 7`               | `minimumReleaseAge: "7 days"`; use `"14 days"` where Renovate auto-merges third-party dependencies (Renovate's own recommendation). Add `internalChecksFilter: "strict"` so no branch or PR appears before the age passes.                           |
| `github-actions` ecosystem plus SHA pins | `extends: ["config:best-practices"]`, which brings `helpers:pinGitHubActionDigests`, `docker:pinDigests`, `security:minimumReleaseAgeNpm`, and `:configMigration`. `config:base` is the legacy name for `config:recommended`; prefer best-practices. |
| `groups`                                 | `packageRules` with `groupName`, or a `group:` preset                                                                                                                                                                                                |

Security updates bypass the release-age delay on both tools.

## Auto-merge

Renovate merges natively; no workflow and no `fetch-metadata`:

```js
module.exports = {
  platformAutomerge: true,
  packageRules: [{ matchUpdateTypes: ["minor", "patch"], automerge: true }],
};
```

`platformAutomerge` hands the merge to GitHub's native auto-merge, so steps 1 and 2 are the gate. The ruleset must name a required status check, or GitHub merges as soon as the PR's other requirements are met, tests passing or not (Renovate's docs carry the same warning). `allow_auto_merge=true` (step 2) is a prerequisite here too.

In `mlb-systems`, opt in with the shared preset instead of writing the rules: `extends: ["local>mlb-systems/renovate:automerge"]` in `.github/renovate-config.js`. It auto-merges minor and patch updates only; majors, pins and digests stay manual, and the `mlb-systems/renovate` workflow bump never auto-merges. Its three prerequisites: `allow_auto_merge` on, an active ruleset with a `required_status_checks` rule, and the Renovate App outside every bypass list.

**A required approval keeps a human in the loop.** With `required_approving_review_count` of 1 or more, or code-owner review on, auto-merge waits for a human approval and then merges; it removes the merge click and the wait for green checks, and no more. An App can neither approve its own PR nor be a code owner. Adding the Renovate App to the bypass list does not fix this: a bypass skips the required checks too, so a red PR merges. Choose per repo:

- **Keep the approval** where a merge deploys or touches CI that runs with secrets (the default).
- **Narrow CODEOWNERS** to the paths that need a human, and add a workflow that approves Renovate minor and patch PRs with another App's token once checks pass.
- **Drop auto-merge** and merge by hand.

## Identity

- Run Renovate under a GitHub App token. PRs opened with `GITHUB_TOKEN` trigger no workflows (the loop-trap, see `github-app-token`).
- `platformCommit: true` makes commits through the API, so GitHub signs them; that matters only where `required_signatures` is on.
- The PR author is the App's bot login (e.g. `mlb-renovate[bot]`); key identity checks on `github.event.pull_request.user.login`.

## Config file

The shared workflow hands `.github/renovate-config.js` to Renovate as its global config and sets `RENOVATE_EXTENDS` to the base preset. `extends` in the file merges with `RENOVATE_EXTENDS`: the file's entries come first and the env's follow, so name only the presets the repo adds. Validate a change with `npx --yes --package renovate@latest renovate-config-validator --strict .github/renovate-config.js`.

## Shared setups

In `mlb-systems`, call the shared workflow and copy the template from the `mlb-systems/renovate` README. Its caller spec pins the call by full SHA with a trailing release tag (`# vX.Y.Z`), passes the four named secrets explicitly (no `secrets: inherit`), and sets `permissions: contents: read`. It takes a `runner` input that defaults to `self-hosted`; an `mlb-systems` repo sets `runner: mlb-systems-ghec` beside `repository:`.

## Alerts

Renovate's `vulnerabilityAlerts` read GitHub's Dependabot alerts, so the `vulnerability-alerts` call in Repo security settings stays. With Dependabot security updates also on, expect duplicate security PRs; choose one. zizmor's `dependabot-cooldown` audit covers only Dependabot, so the Renovate config itself is the check.
