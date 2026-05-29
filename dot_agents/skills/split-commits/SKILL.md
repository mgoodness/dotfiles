---
name: split-commits
description: Analyze pending git changes, group them into clean conventional commits, propose commit messages, and optionally execute the split with careful hunk staging.
---

# Split Commits

Use this skill when the user wants to turn a dirty working tree into a small set of well-scoped commits, especially when they want Conventional Commits subjects and a staging plan.

## Goals

- Separate unrelated changes into distinct commits.
- Keep each commit internally coherent and easy to review.
- Use Conventional Commits subjects with sensible scopes.
- Avoid mixing formatting-only, config-only, and behavior changes unless they clearly belong together.
- Preserve user intent: propose the split first, then create commits only if the user asks.

## Default workflow

1. Inspect the repo state with:
   - `git --no-pager status --short`
   - `git --no-pager diff --stat`
   - `git --no-pager diff --cached --stat`
   - targeted `git --no-pager diff -- <paths>` for changed files
2. Group changes by intent, not just by directory.
   - Prefer one commit per behavior change, feature, fix, cleanup, or tooling update.
   - Split mixed files by hunk when necessary.
3. Propose a commit plan before making changes unless the user explicitly asks you to run it immediately.
4. Draft Conventional Commit subjects.
   - Prefer `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `build`, or `ci`.
   - Add a scope when it improves clarity.
   - Keep subjects short, imperative, and review-friendly.
5. If the user approves execution:
   - stage files or hunks carefully
   - commit in the agreed order
   - keep unrelated unstaged changes out of each commit
   - re-check status after each commit when needed
6. Finish with:
   - the created commit list
   - any remaining unstaged or uncommitted files
   - any hook or formatter behavior encountered during commit

## Splitting rules

### Good reasons to split

- Different user-visible behaviors changed
- Separate tools or subsystems changed independently
- One file contains unrelated hunks
- Personal editor settings are mixed with project changes
- Mechanical cleanup is mixed with functional edits

### Good reasons to combine

- Multiple files implement one coherent change
- A tiny formatting cleanup is in the same file as the main behavior change and clearly belongs with it
- Renames, follow-up callsite fixes, and config needed for the same feature

## Conventional Commit guidance

Use the smallest accurate type.

- `feat(scope): ...` for new behavior or tooling additions
- `fix(scope): ...` for bug fixes or behavior corrections
- `chore(scope): ...` for maintenance, local settings, cleanup, or non-user-facing config
- `refactor(scope): ...` for structure changes without behavior change
- `docs(scope): ...` for documentation-only updates

Pick scopes from the repo's structure and language used by the user. Examples:

- `feat(zed): switch default editor to Zed Preview`
- `fix(fish): export Tide command visibility variables`
- `chore(git): remove gitconfig modelines from managed config files`

## Execution details

When the user asks you to run the split:

- Use `git add` for whole-file commits.
- Use `git add -p` for mixed files.
- If pre-commit hooks modify files during commit, inspect the new staged/unstaged state and fold formatter-only follow-up changes into the commit they belong to.
- Do not accidentally commit unrelated local settings or user-private files unless the user included them.
- If a file must be split across commits, explain which hunks belong to which commit.

## Communication pattern

When proposing a plan, include:

- the ordered commit list
- which files or hunks belong to each commit
- a short reason for each grouping

When execution finishes, include:

- commit hashes and subjects
- any skipped files
- whether the working tree is clean

## Safety rules

- Never rewrite or discard user changes without asking.
- Do not commit automatically unless the user asked you to execute the plan.
- If the working tree includes ambiguous mixed hunks, say so and propose the safest split.
- If the requested number of commits would force unrelated changes together, say that clearly and suggest a better split.
