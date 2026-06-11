---
name: jira-to-pr
description: Create a Jira ticket in the active sprint, assign it to the current user, mark it In Progress, create a branch with the ticket ID, draft a conventional commit message for staged files, and open a pull request. Use when the user wants to start a ticket and open a PR, mentions "create a ticket and branch", "spin up a ticket", or asks to go from ticket to PR.
---

# Jira → PR

End-to-end flow: Jira ticket → In Progress → branch → commit draft → PR.

## Workflow

### 1. Gather context (parallel)

Run all of these at once:

- `jira me` — confirm current user (for context; CLI uses configured auth automatically)
- `git status` + `git diff --cached --stat` — inspect staged files
- `git remote -v` — confirm remote for PR

### 2. Find the active sprint + project key

```sh
jira sprint list --board 2093 --state active --plain --columns id,name
```

Take the first (current) active sprint → note its `id`.

Get the project key from the configured default or ask the user. If unknown, run:

```sh
jira project list --plain --columns key,name
```

and pick the relevant project.

### 3. Create the Jira ticket

```sh
jira issue create \
  --type Task \
  --summary "<user-provided title>" \
  --no-input
```

Note the returned key (e.g. `OZZI-2225`).

Then add it to the active sprint:

```sh
jira sprint add <sprint-id> <TICKET-KEY>
```

### 4. Transition to In Progress

```sh
jira issue move <TICKET-KEY> "In Progress"
```

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

Resolves [<TICKET-KEY>](https://<your-jira-site>/browse/<TICKET-KEY>)

## Changes

- `path/to/file` — what it does
```

## CLI reference

| Action              | Command                                                    |
| ------------------- | ---------------------------------------------------------- |
| Current user        | `jira me`                                                  |
| List active sprints | `jira sprint list --board 2093 --state active`             |
| Create issue        | `jira issue create --type Task --summary "..." --no-input` |
| Add to sprint       | `jira sprint add <sprint-id> <TICKET-KEY>`                 |
| Transition issue    | `jira issue move <TICKET-KEY> "In Progress"`               |
| List projects       | `jira project list --plain --columns key,name`             |

Board ID `2093` is the configured default (Cloud Platform Sprint Board).

## Edge cases

- **No staged files:** skip commit draft and note it; still create ticket + branch + PR (GitHub requires ≥1 commit ahead of base — make an empty init commit if needed with `--allow-empty`).
- **User specifies a different project:** pass `--project <KEY>` to `jira issue create`.
- **`jira issue move` status name mismatch:** run `jira issue move <KEY>` without a status arg to list available transitions interactively.
