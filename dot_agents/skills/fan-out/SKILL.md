---
name: fan-out
description: Fan a batch of tickets out into parallel agent tabs — one git worktree per ticket, each opened in a Macterm tab with the agent's /implement command staged. Use when the user asks whether tickets can be worked in parallel, wants worktrees or agent tabs for several tickets at once, or says to fan out / spin up a batch.
---

# Fan Out

Stand each parallel ticket up as its own agent tab: an isolated worktree, a Macterm tab rooted there, and the agent's `/implement` for that ticket staged in its input box. This session stays put and never enters a worktree.

A fan-out is only as good as its set. Two tickets that must share a file, a path, or a name are not parallel, however independent they look; fan them out anyway and the collision surfaces later as a merge rather than now as a decision. So the job is three moves: prove the set is parallel, cut a worktree per ticket, open an agent tab per worktree.

## 1. Prove the set is parallel

Start from the **frontier**: the tickets that are open with no open blocker. If the repo documents its own frontier query or wave check, use it — a repo's ticket-slicing note is the authority over this section's general shape.

Wave-check the frontier for the two collisions: tickets that _create_ the same foundation (a manifest, a lockfile, a workflow, a package layout), and tickets that must agree on a path, name, or surface that no ticket decides. Either one means the frontier is not yet the wave.

When the check fails, fix the tracker before cutting worktrees, so no branch is built on a foundation that is about to move:

- **Foundation collision** → land the foundation first, or widen one ticket to own it.
- **Undecided shared interface** → add a small contract ticket the others block on.
- **Human prerequisite** (a credential, a dashboard step) → a `ready-for-human` ticket, kept off the agent branches.

Record each remedy as a real blocking edge, so the tracker's own frontier query reflects it.

**Done when** every ticket you are about to fan out has no open blocker, and every ticket you are holding back carries an edge naming its blocker.

## 2. Cut a worktree per ticket

One worktree per ticket off the trunk, named `issue-<number>-<slug>` so its path traces back to the ticket:

```sh
wt switch --create issue-<n>-<slug> --base <trunk> --no-cd
```

`--no-cd` is the point: you are spawning siblings, not moving in. Run this repo's worktree hooks rather than reaching for `--yes` on your own judgement; the trust decision is the user's.

**Done when** `git worktree list` shows exactly one clean worktree per ticket, each on its own branch off the trunk.

## 3. Open an agent tab per worktree

In the repo's Macterm project, per worktree: open a tab rooted at the worktree, name it for the ticket, launch the agent, and stage that ticket's `/implement`.

```sh
macterm tab new --project <project> --run "cd <worktree-path>"
macterm tab rename <tab-id> "#<n> · <short title>"
macterm pane run --session <session> "pi"                             # launch the agent
macterm pane run --session <session> --no-submit "/implement #<n>"    # stage, don't submit
```

Two rules make the targeting reliable (the `macterm` skill has the CLI's own mechanics):

- **Target by session, not by pane index.** `--session macterm-…` survives a Macterm relaunch; `pane:N` means the _focused_ tab's Nth pane, so a command aimed that way can land in a tab you were not aiming at.
- **Put the selector flags before the command.** `pane run <command> …` treats everything after the command as more command, so `pane run "pi" --session <s>` self-targets the calling pane and types `pi --session <s>` into it. Write `pane run --session <s> "pi"`.

Wait for the agent's own footer before staging: poll `macterm pane dump` for the line naming the worktree. That footer is the readiness signal — `pane list`'s `process` field can lag the agent's start by half a minute, so treat it as advisory.

**Done when** each ticket has exactly one tab, titled for it, with the agent idle at its worktree and `/implement #<n>` staged but unsubmitted. Leave the commands staged: the human pressing Enter in each tab is what starts the work, which keeps the fan-out itself from writing any code.

## Teardown

Tearing the worktrees down after their PRs merge is `cleanup-branch`'s job, one branch at a time — not a byproduct of the next fan-out.
