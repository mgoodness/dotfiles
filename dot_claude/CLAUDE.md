# Global Claude Rules

## Commits

Prefer small, focused commits over large omnibus ones.

- **One logical change per commit.** If a task touches multiple concerns (e.g., a new feature + a bug fix + a refactor), split them into separate commits rather than lumping them together.
- **Stage selectively.** Use `git add -p` or per-file staging to include only the files and hunks that belong to the current logical change.
- **Commit as you go.** After completing a coherent unit of work — even mid-task — commit it before moving on to the next change. Don't accumulate a pile of unrelated edits.
- **Keep commits reviewable.** Each commit should be understandable in isolation: a reviewer should be able to read the diff and the message and know exactly what changed and why.
- **Scope drives the message.** Use the Conventional Commits format (`type(scope): description`). If you can't write a single-line subject that accurately describes the diff, the commit is probably too large.

### Heuristics for splitting

| Signal                                   | Action                                     |
| ---------------------------------------- | ------------------------------------------ |
| Commit message needs "and" or "also"     | Split into two commits                     |
| Diff spans unrelated files or concerns   | Split by concern                           |
| One change is a prerequisite for another | Commit the prerequisite first              |
| A refactor is mixed with a feature       | Refactor commit first, then feature commit |
