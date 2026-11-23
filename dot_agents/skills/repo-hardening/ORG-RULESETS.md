# Org rulesets: one rule set for many repos

Step 1 of `SKILL.md` creates a ruleset per repo. In an org with a dozen or more repos, per-repo rulesets drift: names, required checks, and approval counts diverge, and each change is a dozen API calls. Org-level rulesets apply one definition to every repo a **custom property** selects. The JSON payloads beside this file (the `mlb-systems` rulesets) are the steady state.

Use it when several repos share one policy; a lone repo, or one whose policy differs from every other, takes the per-repo ruleset in step 1.

## Design

One **base** ruleset covers every enrolled repo; each **layer** adds one concern and is selected by its own property. Rules from all matching rulesets combine to the most restrictive, so a layer only ever adds.

| Ruleset                              | Property that selects it                                   | Payload                                                        | Adds                                                                                                                                                                                                                        |
| ------------------------------------ | ---------------------------------------------------------- | -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `protect-default-branch` (base)      | `default-branch-protection` is `standard` or `code-owners` | [`ORG-RULESET-BASE.json`](ORG-RULESET-BASE.json)               | `~DEFAULT_BRANCH`; no deletion or force-push; linear history; squash only; 1 approval; last-push approval; stale-review dismissal; thread resolution; required check `CI` (strict off); Admin bypass in `pull_request` mode |
| `protect-default-branch-code-owners` | `default-branch-protection` is `code-owners`               | [`ORG-RULESET-CODE-OWNERS.json`](ORG-RULESET-CODE-OWNERS.json) | code-owner review                                                                                                                                                                                                           |
| `protect-default-branch-strict`      | `require-up-to-date` is `true`                             | [`ORG-RULESET-STRICT.json`](ORG-RULESET-STRICT.json)           | the branch must be current with the base before merging                                                                                                                                                                     |

- `default-branch-protection` is a single-select property; `require-up-to-date` is a true/false property. A repo with no value gets no protection. Create each once: `gh api -X PUT orgs/<org>/properties/schema/<name> --input -`. A non-required true/false property takes no `default_value` (the API answers 422 "Default value must be empty").
- Set values in bulk: `gh api -X PATCH orgs/<org>/properties/values` with `repository_names` and `properties`.
- Keep code owners and up-to-date as separate layers. They suit different repos: code owners where non-admins commit regularly, up-to-date where a merge deploys. A repo that later gets a per-repo merge queue drops `require-up-to-date` and keeps its code owners.
- Admin bypass (`RepositoryRole` id 5, `pull_request` mode) skips every rule in the ruleset, required checks included, so treat it as break-glass and list only human roles; Apps (Renovate, release automation) stay off the list.
- Code-owner review is what stops an App from approving a writer's PR: an App cannot be a code owner. Enroll a repo in `code-owners` where writers other than admins commit; where only admins commit the gap is moot, since an admin can bypass anyway.
- A merge queue lives in a repo-level ruleset (see Merge queue in `SKILL.md`), so it sits beside these rulesets, not in them.

## Each enrolled repo needs first

- A job named exactly `CI` that reports on every PR: no `paths:` filter; triggers on `pull_request`, `merge_group`, and a push to the default branch. With several jobs, make `CI` the gate over them with `if: ${{ !cancelled() }}` (`always()` runs the gate inside a cancelled run and reports a spurious failure).
- Squash-only repo settings (step 2).
- A validated CODEOWNERS file in `code-owners` repos: `gh api repos/<owner>/<repo>/codeowners/errors` is empty, and the owning team has write access (otherwise the review is unsatisfiable).
- Shared CI actions that use only GitHub-owned actions, so repos with `allowed_actions: selected` can call them (`gh api repos/<owner>/<repo>/actions/permissions` shows which repos restrict).
- No signed-commit requirement: see the `required_signatures` bullet in step 1.

## Rollout

1. Create the properties and the rulesets with `"enforcement": "evaluate"`.
2. Set the property on repos that already have a `CI` job.
3. Read the results in Rule Insights, or `gh api "orgs/<org>/rulesets/rule-suites?time_period=week&per_page=100"` then `gh api orgs/<org>/rulesets/rule-suites/<id>` for an event's `rule_evaluations`. Last-push and code-owner findings on authors' own merges are expected. A "must not contain merge commits" finding on a PR merge comes from GitHub's temporary test-merge commit; the active repo ruleset reports the same.
4. Switch to `active` (`gh api -X PUT orgs/<org>/rulesets/<id> --input <file>` with `"enforcement": "active"`).
5. Delete each enrolled repo's own branch ruleset so one system governs. `gh api repos/<owner>/<repo>/rulesets` also lists the org rulesets, so filter on `source_type == "Repository"` before deleting, and save each JSON first. Keep tag rulesets.
6. Moving a layer's requirement (for example `strict` out of the base): create the layer and enrol its repos first, then relax the base, so no repo goes unprotected in between.

## Done when

- `gh api repos/<owner>/<repo>/rules/branches/<branch>` lists the org rulesets for each enrolled repo, with `CI` as the required check and no repo-level branch ruleset left.
- A PR from a non-admin in an enrolled repo cannot merge without another person's approval. Test with a throwaway PR; Rule Insights alone only shows admin and bot merges.
