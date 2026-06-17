---
name: jira-to-pr
description: Create a Jira ticket in the active sprint, assign it to the current user, mark it In Progress, create a branch with the ticket ID, draft a conventional commit message for staged files, and open a pull request. Use when the user wants to start a ticket and open a PR, mentions "create a ticket and branch", "spin up a ticket", or asks to go from ticket to PR.
---

# Jira → PR

End-to-end flow: Jira ticket → In Progress → branch → commit draft → PR.

## Workflow

### 1. Gather context (parallel)

Run all of these at once:

- `atlassianUserInfo` — get `account_id` for assignment
- `getAccessibleAtlassianResources` — get `cloudId`
- `git status` + `git diff --cached --stat` — inspect staged files
- `git remote -v` — confirm remote for PR

### 2. Find the active sprint + project

```jql
assignee = currentUser() AND sprint in openSprints() ORDER BY updated DESC
```

Pull one issue to get `customfield_10180` (sprint array) → extract sprint `id`.
The project key comes from any returned issue's `fields.project.key`.

### 3. Create the Jira ticket

`createJiraIssue` with:

- `projectKey` from step 2
- `issueTypeName`: Task (default; adjust if user specifies)
- `summary`: user-provided title
- `assignee_account_id`: from step 1
- `additional_fields`: `{"customfield_10180": <sprint_id>}` (integer, not object)

Note the returned `key` (e.g. `OZZI-2225`).

### 4. Transition to In Progress

`getTransitionsForJiraIssue` → find the "In Progress" transition id →
`transitionJiraIssue` with that id.

### 5. Create and push the branch

```sh
git checkout -b <TICKET-KEY>/short-slug-of-title
git push origin <TICKET-KEY>/short-slug-of-title
```

Branch naming convention: `<TICKET-KEY>/<kebab-case-summary>`
Example: `OZZI-2225/create-abfab-projects-argocd`

### 6. Draft conventional commit message

Inspect staged files (`git diff --cached --stat` + read key files) and produce:

```
<type>(<scope>): <short description> [<TICKET-KEY>]

<body: what changed and why, bullet points per file/group>
```

**Type selection:**
| Staged content | Type |
|---|---|
| New files / features | `feat` |
| Bug fixes | `fix` |
| Config / infra changes | `chore` |
| Refactors | `refactor` |
| Docs only | `docs` |

**Scope:** the top-level directory of the changed files (e.g. `akuity-projects`, `applications/maps`).

Present the full message to the user — do **not** commit automatically unless asked.

### 7. Create the pull request

If the branch has no commits yet (empty branch), commit the staged files first:

1. Copy staged files into the branch (or `git stash` + apply in worktree if needed)
2. Commit with the drafted message
3. Push

Then:

```sh
gh pr create \
  --title "[<TICKET-KEY>] <user-provided title>" \
  --body "..." \
  --base main \
  --head <branch>
```

PR body template:

```md
## Summary

<one-liner>

Resolves [<TICKET-KEY>](<jira-url>/browse/<TICKET-KEY>)

## Changes

- `path/to/file` — what it does
```

## Key field reference

| Field               | Value                                              |
| ------------------- | -------------------------------------------------- |
| Sprint custom field | `customfield_10180`                                |
| Sprint value format | integer (e.g. `11718`), NOT `{"id": 11718}`        |
| Cloud ID source     | `getAccessibleAtlassianResources` or site hostname |

## Edge cases

- **No staged files:** skip commit draft and note it; still create ticket + branch + PR (GitHub requires ≥1 commit ahead of base — make an empty init commit if needed with `--allow-empty`).
- **Multiple Atlassian resources:** use the one matching the user's site or ask.
- **User specifies a different project:** use that project key instead of inferring from open sprint.
