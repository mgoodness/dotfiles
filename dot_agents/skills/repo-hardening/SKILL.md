---
name: repo-hardening
description: >
  Harden a GitHub repo so required checks and automated merges actually bite: rulesets, merge
  settings, Dependabot with auto-merge, immutable releases, signed commits, repo security
  settings, and Actions security practices (SHA pinning, token scoping, injection). Use when
  auditing an existing ruleset or merge settings, or when zizmor/actionlint flags a workflow.
  Defers CI content to a language skill (e.g. `go-ci`), release-please to `release-please`, and
  App-token mechanics to `github-app-token`.
---

# Repo Hardening: Making Required Checks and Auto-Merge Actually Bite

A required-check status and an "auto-merge" button are both easy to turn on and easy to leave toothless. This skill is the dependency chain that makes them real: name the check correctly, gate on it with a ruleset, back that with repo-wide merge settings that agree with the ruleset, then layer Dependabot and its auto-merge on top. Each step produces something the next one needs, so skipping the order reproduces the failure this skill exists to prevent: an auto-merge that fires with nothing gating it.

Nothing here is language-specific. What the required CI job builds, tests, and lints belongs to a language skill (`go-ci` for Go), which points back here for the ruleset, Dependabot, and hardening. Cutting a versioned release from the commit history belongs to `release-please`.

## Tiers

Apply the tier the repo has earned:

- **Baseline**, every repo: [Repo security settings](#repo-security-settings), step 3 (Dependabot config), and [Security hardening](#security-hardening-what-zizmor-will-flag).
- **Gated**, a repo with a required CI job: Baseline plus steps 1, 2, and 4. A repo with no CI job takes a light ruleset instead: keep `deletion`, `non_fast_forward`, and `required_signatures` from [`RULESET-PAYLOAD.json`](RULESET-PAYLOAD.json), and drop `pull_request`, `required_status_checks`, and `required_linear_history`.
- **Publishing**, a repo that cuts GitHub Releases: Gated plus [Immutable releases](#immutable-releases--locking-published-tags-and-assets).

## 1. Repository ruleset — turning the required check on

Whatever job gates merges (a language skill's CI workflow, e.g. `go-ci`) is what the ruleset and auto-merge (step 4) both key off. Rulesets are the current mechanism; an existing repo with classic branch protection migrates, and the classic rule comes off once the ruleset covers the same ground, since two systems at once yield a most-restrictive combination that is hard to audit.

Creating a ruleset needs repo-admin permissions the default `GITHUB_TOKEN` lacks, so this is a one-time, admin-run call. Adapt the `context` value in [`RULESET-PAYLOAD.json`](RULESET-PAYLOAD.json) to the CI job's `name:` field, then:

```sh
gh api -X POST repos/<owner>/<repo>/rulesets --input RULESET-PAYLOAD.json
```

Without it the CI job still runs and reports a status; it blocks nothing.

- `conditions.ref_name.include` is a glob (`refs/heads/main`, or `refs/heads/release/*` for several branches).
- `deletion`, `non_fast_forward`, `required_linear_history`, and `required_signatures` are rule _types_, each opted into by inclusion. Omitting a type leaves that constraint unenforced.
- `required_status_checks`: `context` matches the CI job's `name:` field, not its `jobs.<id>` key. `integration_id: 15368` (the GitHub Actions app) pins the check's source, so another app or a plain commit status cannot satisfy it.
- `strict_required_status_checks_policy: true` requires the PR branch be current with the base. The cost is rebases: every merged Dependabot PR makes its siblings stale (see Common Mistakes). Keep it on by default; set it `false` on a repo where Dependabot volume makes rebases the dominant cost.
- `pull_request` replaces classic `required_pull_request_reviews`. `required_approving_review_count: 0` is the solo-maintainer choice: the PR and its checks stay required, a second human does not. Raise it to 1 or more once a second maintainer exists.
- **`bypass_actors: []` is the load-bearing line.** Rulesets carry no implicit admin exemption, so an empty list binds everyone, repo and org admins included. Add an entry only for a bypass you want (e.g. `{"actor_type": "OrganizationAdmin", "bypass_mode": "always"}`) and confirm its exact shape against current docs; this is the newest part of the payload.
- `required_linear_history` forces squash or rebase; pair it with step 2's repo setting. The `pull_request` rule's `allowed_merge_methods` enforces the same restriction at ruleset scope for per-branch differences; verify its shape against current docs first.
- `required_signatures` is the house default and takes no parameters. It binds admins too when `bypass_actors` is empty, so audit what pushes to the branch: GitHub API-created commits carry GitHub's web-flow signature and show Verified, so the `github-app-token`/release-please path survives; a CI runner pushing with a plain token and no signing key does not. For that repo, drop the rule from the payload.
- Rollout: on GitHub Enterprise, `"enforcement": "evaluate"` records would-be violations in Rule Insights without blocking. Use it on an existing repo before switching to `active`. Other plans start at `active`.

## 2. Repo merge settings — no merge commits, auto-delete branches

Repo-level settings (`Settings → General → Pull Requests`, or the call below), separate from the ruleset and load-bearing beside it:

```sh
gh api -X PATCH repos/<owner>/<repo> \
  -F allow_merge_commit=false \
  -F allow_squash_merge=true \
  -F allow_rebase_merge=true \
  -F delete_branch_on_merge=true \
  -F allow_auto_merge=true
```

- `allow_merge_commit=false` is what enforces step 1's `required_linear_history`; either one alone leaves the two disagreeing about history.
- `delete_branch_on_merge=true` removes merged head branches so stale ones do not pile up.
- `allow_auto_merge=true` is the prerequisite for step 4: without it `gh pr merge --auto` is unavailable.

## 3. Dependabot config

`gomod`/`npm`/`pip`/etc. plus `github-actions` ecosystems, weekly schedule, `cooldown.default-days >= 7` (shorter trips zizmor's `dependabot-cooldown` audit). Cooldown delays version updates only; security updates arrive immediately. `groups` batches an ecosystem's updates into one PR, cutting the rebase churn step 1 describes.

## 4. Dependabot auto-merge

Gate on `dependabot/fetch-metadata`'s `update-type` output: auto-merge `semver-minor` and `semver-patch`, leave `semver-major` for manual review, since every major bump is a real compatibility question.

Use plain `pull_request` with an explicit `permissions:` block. GitHub's docs say Dependabot-triggered `pull_request` runs start with a read-only token and that the `permissions:` key raises it; the `contents: write` and `pull-requests: write` grants below suffice, so the privileged `pull_request_target` event is unnecessary here. Allowlisting the two update types in the `if:` makes an empty or unexpected output skip the merge:

```yaml
on: pull_request
permissions: {}
jobs:
  automerge:
    if: github.event.pull_request.user.login == 'dependabot[bot]'
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - id: metadata
        uses: dependabot/fetch-metadata@<sha> # vX.Y.Z
      - if: >-
          steps.metadata.outputs.update-type == 'version-update:semver-minor' ||
          steps.metadata.outputs.update-type == 'version-update:semver-patch'
        run: gh pr merge --auto --squash "$PR_URL"
        env:
          PR_URL: ${{ github.event.pull_request.html_url }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This is safe only with steps 1 and 2 in place (a ruleset requiring the CI job's check, and the repo's "Allow auto-merge"); without either, "enable auto-merge" merges on PR open with zero verification. A merge queue changes one thing: the built-in `GITHUB_TOKEN` cannot enqueue, so mint an App token for the `gh pr merge` step (`github-app-token`).

Keep auto-merge scoped to Dependabot. Mechanical, high-volume dependency bumps are worth automating; auto-merging human-authored PRs is a per-repo call a maintainer makes explicitly, per PR.

## Repo security settings

One-time, admin-run calls, the Baseline tier's repo-level half:

```sh
gh api -X PUT repos/<owner>/<repo>/actions/permissions/workflow \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
gh api -X PUT repos/<owner>/<repo>/vulnerability-alerts
gh api -X PUT repos/<owner>/<repo>/automated-security-fixes
gh api -X PATCH repos/<owner>/<repo> \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
# public repos: hold first-run workflows from any outside contributor for approval
gh api -X PUT repos/<owner>/<repo>/actions/permissions/fork-pr-contributor-approval \
  -f approval_policy=all_external_contributors
```

- `default_workflow_permissions=read` makes every workflow ask for what it writes; `can_approve_pull_request_reviews=false` keeps a workflow token from approving PRs, which would otherwise satisfy a required-review rule.
- Secret scanning and push protection are free on public repos; private repos need GitHub Secret Protection.
- An org policy that owns a setting answers with a 409; set it at org level instead.
- Code scanning (CodeQL) and the "require code scanning results" ruleset rule are worth adding on repos with application code, and a ruleset rule can block PRs that introduce secret-scanning alerts (public preview as of Sep 2026).

## Immutable releases — locking published tags and assets

A repo-admin, one-time `gh api` call independent of steps 1–4; it hardens the _release_ supply chain.

```sh
gh api -X PUT repos/<owner>/<repo>/immutable-releases
```

- A published release's Git tag locks to its commit: it cannot be moved, retargeted, or deleted while the release exists, and the name cannot be reused even if the repo is deleted and recreated. Attached assets are protected from modification or deletion; title, notes, and the prerelease/latest flags stay editable. Publishing mints a release attestation (a verifiable record binding tag, commit SHA, and asset list) at no extra configuration.
- **Publish as late as possible: draft, attach every asset, then publish.** The default release-please + GoReleaser pipeline breaks on this: release-please publishes the Release the moment it creates the tag, and GoReleaser then attaches artifacts to that already-published release, which GitHub forbids. Hold the release as a draft until every artifact is attached (release-please's `draft`/`force-tag-creation` config, see `release-please`'s draft-mode trap), and have the downstream tool finish that same draft (GoReleaser's `use_existing_draft`, see `go-ci`). Confirm the reorder before enabling the setting, or the next tag push fails.
- An org admin can mandate it repo-wide (`PUT /orgs/{org}/settings/immutable-releases` with `enforced_repositories: all`/`none`/`selected`); if the org enforces `all`, the per-repo call only confirms existing state.

## Security hardening (what zizmor will flag)

- **Pin every third-party action to a commit SHA with a trailing `# vX.Y.Z` comment.** The comment is what lets Dependabot's `github-actions` ecosystem keep bumping it. Resolve the SHA from the tag's **commit**: for an annotated tag, `git/refs/tags/<tag>` returns the tag object's SHA (`type: "tag"`), one level short. Dereference it (`git/tags/<that-sha>`) or run `git rev-parse <tag>^{commit}`. Actions accepts the tag object's SHA, so nothing fails until zizmor's `ref-version-mismatch` audit flags it.
- **Enforce the pin with `sha_pinning_required`**, switched on after every workflow in the repo is pinned. Read-modify-write the permissions endpoint, since the `PUT` also carries `enabled` and `allowed_actions`, which a bare body would reset:
  ```sh
  gh api repos/<owner>/<repo>/actions/permissions --jq '. + {sha_pinning_required: true}' \
    | gh api -X PUT repos/<owner>/<repo>/actions/permissions --input -
  ```
  An org admin sets the same field on `orgs/<org>/actions/permissions`. It covers every step-level action, GitHub-owned and same-org included; a reusable workflow (job-level `uses:`) may still name a tag, so zizmor's `unpinned-uses` covers those.
- **Declare `permissions: {}` at the top of each workflow and grant per job** the scopes that job needs (zizmor's `excessive-permissions`).
- **`persist-credentials: false`** on any `actions/checkout` step that does not push afterward, and on every step that checks out untrusted PR code.
- **Pass untrusted context through `env:`.** Values like a PR title, branch name, or `head.ref` reach a `run:` script as `"$VAR"`, never as an interpolated `${{ }}` expression (zizmor's `template-injection`).
- **Bot identity**: key checks on `github.event.pull_request.user.login`. `github.actor` is spoofable (zizmor's `bot-conditions`).
- **Prefer `pull_request`.** `pull_request_target` and `workflow_run` run with a write token and secrets, which is why zizmor flags them (`dangerous-triggers`). A workflow that genuinely needs one says why in the suppression, naming both facts: no checkout of PR code, and PR-derived values flow only through `env:`:
  ```yaml
  on: pull_request_target # zizmor: ignore[dangerous-triggers] no checkout of PR code; PR-derived values only flow through env:
  ```
- **Scope minted App tokens down** with `permission-*` inputs so a job that pushes a tag and opens a PR holds only those grants. Mechanics, one App across a repo's automation, and the workflow-run approval gate live in `github-app-token`.
- **Authenticate to clouds and registries with OIDC** (short-lived tokens, `id-token: write` on the one job that needs it) in place of long-lived secrets, and publish build provenance with `actions/attest`. The recipe belongs to the language skill (`go-ci`).

## Common Mistakes

Symptom → cause, for diagnosing a repo that looks hardened and is not:

- **Auto-merge fires with nothing gating it** → no ruleset, or its `context` does not match the CI job's `name:`.
- **Required check stuck on "Expected — Waiting for status"** → `context` names the `jobs.<id>` key, or `integration_id` does not match the app that reports the check.
- **Dependabot PRs keep failing checks after a fix lands on the base branch** → merging the fix does not re-run open PRs; comment `@dependabot rebase`.
- **`gh pr merge` 403s in the auto-merge workflow** → the `permissions:` block is missing or too narrow, so Dependabot's default read-only token applies.
- **Unsigned commit cannot be pushed, even by an admin** → `required_signatures` is on and `bypass_actors` is empty; audit the pusher.
- **The next tag push fails after enabling immutable releases** → release-please still publishes before assets are attached; switch the pipeline to draft-first.
- **zizmor `ref-version-mismatch`** → the pin names an annotated tag's own object SHA, not its commit.

## Completion criterion

Each claim is checkable with one call:

- **Baseline:** `gh api repos/<owner>/<repo>/actions/permissions/workflow` prints `default_workflow_permissions: read` and `can_approve_pull_request_reviews: false`; `gh api repos/<owner>/<repo>/actions/permissions --jq .sha_pinning_required` prints `true`; secret scanning, push protection, and Dependabot security updates are enabled (repo-level `security_and_analysis`); the Dependabot config sets `cooldown`; every third-party action in every workflow carries a SHA pin with a `# vX.Y.Z` comment.
- **Gated:** the ruleset is active on the target branch; its required-check `context` matches the CI job's `name:`; merge settings disable merge commits and enable auto-merge; the auto-merge workflow is present and runs on `pull_request`; signed commits are required on the target branch.
- **Publishing:** `gh api repos/<owner>/<repo>/immutable-releases --jq .enabled` prints `true`, with the release pipeline draft-first.
