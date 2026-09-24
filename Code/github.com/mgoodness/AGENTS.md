# AGENTS.md

Applies to every repository under this directory. Repo-specific instructions live in each repo's own `AGENTS.md`; where the two disagree, the repo's wins.

## Engineering skills

Per-repo `docs/agents/*.md` is the authoritative configuration for the engineering skills — issue tracker, triage labels, domain docs, ticket slicing. Read those files before doing flow work, and change them rather than the installed skills under `~/.agents/skills/`: those are vendored from upstream (most from `mattpocock/skills`), a lockfile records their hashes, and local edits are lost on update.

If a skill's behaviour needs to change for you, in preference order: extend the per-repo `docs/agents/` config, add the rule to a repo `AGENTS.md`, add it to this file if it holds everywhere, or package it as a skill in your own dotfiles, at `dot_agents/skills/<name>/`. Upstream it only when it is generally useful and you are willing to maintain it.

## Slicing work into tickets

Before presenting or publishing a set of tickets, run the **wave check** on any group you are about to describe as parallel:

- **Foundation collisions.** Do two of them _create_ the same foundation — a module manifest, lockfile, package layout, CI workflow, or config root? Then they cannot both branch from the trunk: `main` would take two adds of the same file, and a merge conflict on a manifest doesn't resolve itself — someone has to reconcile it by hand. Land the foundation first, or stack the dependents on it. Worktrees do not help when every branch lays the same foundation.
- **Undecided shared interfaces.** Is there a path, name, or surface that two of them must agree on, and that no ticket or spec decides? That is a missing prefactor. Widen the foundation ticket to own it, or add a contract ticket, and add the blocking edges — otherwise each branch invents its own answer and the merge becomes a reconciliation.

Then **state the wave as it actually is** ("one ticket alone, then two in parallel") rather than as it appears by domain. A breakdown that claims three-way parallelism where the truth is one-plus-two is worse than a conservative one, because it invites worktrees that collide.

If the repo has `docs/agents/ticket-slicing.md`, follow it: the full checklist and worked examples live there.
