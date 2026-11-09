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

## Identity

- Run Renovate under a GitHub App token. PRs opened with `GITHUB_TOKEN` trigger no workflows (the loop-trap, see `github-app-token`).
- `platformCommit: true` makes commits through the API, so GitHub signs them and `required_signatures` passes.
- The PR author is the App's bot login (e.g. `mlb-renovate[bot]`); key identity checks on `github.event.pull_request.user.login`.

## Shared setups

In `mlb-systems`, call the shared workflow and copy the template from the `mlb-systems/renovate` README. Its caller spec pins the call by full SHA with a trailing `# main`, passes the four named secrets explicitly (no `secrets: inherit`), and sets `permissions: contents: read`.

## Alerts

Renovate's `vulnerabilityAlerts` read GitHub's Dependabot alerts, so the `vulnerability-alerts` call in Repo security settings stays. With Dependabot security updates also on, expect duplicate security PRs; choose one. zizmor's `dependabot-cooldown` audit covers only Dependabot, so the Renovate config itself is the check.
