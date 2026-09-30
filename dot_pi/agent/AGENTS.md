# Global agent notes

## Changing a skill's behaviour

Skills under `~/.agents/skills/` are vendored from upstream (mostly
`mattpocock/skills`); a lockfile records their hashes, so local edits are lost on
update. To change how a skill behaves, in preference order:

1. Extend the repo's `docs/agents/` config — issue tracker, triage labels, domain
   docs, ticket slicing.
2. Add the rule to the repo's `AGENTS.md`.
3. Add it to this file, if it holds in every project.
4. Package it as a skill in your dotfiles under `dot_agents/skills/<name>/`.

Upstream it only when it is generally useful and you will maintain it.

## Subagent dispatch

- **Code review.** `/code-review` splits into two axes. Dispatch both in parallel
  with the `subagent` tool, passing the skill's step-4 brief as each task's
  `task`: standards → `code-review-standards`, spec → `code-review-spec`. The two
  agents are read-only and role-scoped. Without a `subagent` tool, run both axes
  inline in sequence and say so in the report.
- **Research.** Dispatch to the `research` agent with the `subagent` tool, passing
  the question and any constraints (trusted sources, destination path, output
  format) as the task. It leaves one cited Markdown artefact, reports the path,
  and writes nothing else in the worktree.
- **`/implement-spec`.** Its **exploration subagent** is the `research` agent —
  dispatch it the same way. Its **implementer** and **merger** subagents are
  `implement-spec-implementer` and `implement-spec-merger`: dispatch one
  implementer per ticket (in that ticket's worktree/branch) across the ready
  frontier, then a merger per completed branch onto the integration branch.
  Pass ticket/branch/worktree pointers as the task, not restated ticket
  content — the protocol (worktree checks, `tdd`, merge-before-reporting) is
  already baked into each agent.

## Ticket slicing

Before presenting or publishing tickets — and before calling any group parallel
— run the **wave check** on every ticket in the group:

- **Foundation collision.** Two tickets create the same foundation (module
  manifest, lockfile, package layout, CI workflow, config root). Land the
  foundation first, then stack the dependents on it; one foundation cannot ride
  two branches.
- **Undecided shared interface.** Two tickets must agree on a path, name, or
  surface that no ticket or spec decides. Widen the foundation ticket to own it,
  or add a contract ticket and the blocking edges.

Then **state the wave as it actually is** — "one ticket alone, then two in
parallel" — not as it appears by domain. Claimed three-way parallelism that is
really one-plus-two invites worktree collisions.

For the full checklist and worked examples, read the repo's
`docs/agents/ticket-slicing.md`.
