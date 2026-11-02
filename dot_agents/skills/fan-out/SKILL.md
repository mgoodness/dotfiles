---
name: fan-out
description: Fan a batch of tickets out into parallel agent tabs — one git worktree per ticket, each opened in a Rex tab with the agent's /implement command staged. Use when the user asks whether tickets can be worked in parallel, wants worktrees or agent tabs for several tickets at once, or says to fan out / spin up a batch.
---

# Fan Out

Stand each parallel ticket up as its own agent tab: an isolated worktree, a Rex tab rooted there, and the agent's `/implement` for that ticket staged in its input box. This session stays put and never enters a worktree.

The Rex layout (session per repo, tab per worktree, panes inside) is in the global `AGENTS.md`; the `rex` skill has the CLI mechanics.

A fan-out is only as good as its set. Two tickets that must share a file, a path, or a name are not parallel, however independent they look; fan them out anyway and the collision surfaces later as a merge rather than now as a decision. So the job is three moves: prove the set is parallel, cut a worktree per ticket, open an agent tab per worktree.

## 1. Prove the set is parallel

Fetch and fast-forward the trunk worktree first (`git fetch origin --quiet && git pull --ff-only`, run from the trunk worktree). Both this step's own exploration and step 2's `--base <trunk>` read the trunk worktree's checked-out files, not just its refs — a `git fetch` alone leaves them stale. Skip this and a wave check can clear a collision that a PR merged since you were last here already created, the same way this section exists to catch. A pull that fails (dirty tree, diverged history) means the trunk worktree isn't fit to fan out from yet — resolve that before cutting anything, don't route around it.

Start from the **frontier**: the tickets that are open with no open blocker. If the repo documents its own frontier query or wave check, use it — a repo's ticket-slicing note is the authority over this section's general shape.

Wave-check the frontier for the two collisions: tickets that _create_ the same foundation (a manifest, a lockfile, a workflow, a package layout), and tickets that must agree on a path, name, or surface that no ticket decides. Either one means the frontier is not yet the wave.

When the check fails, fix the tracker before cutting worktrees, so no branch is built on a foundation that is about to move:

- **Foundation collision** → land the foundation first, or widen one ticket to own it.
- **Undecided shared interface** → add a small contract ticket the others block on.
- **Human prerequisite** (a credential, a dashboard step) → a `ready-for-human` ticket, kept off the agent branches.

Record each remedy as a real blocking edge, so the tracker's own frontier query reflects it.

A third pattern doesn't gate this step. An additive registry built for exactly this — a list or struct a caller assembles once and callees register into, so no ticket creates a foundation — still has one call site that wires every registration in: the constructor or builder literal that hands the assembled value to its caller. Two tickets in the wave each adding one field or line there will conflict when the second merges, purely from landing near the same lines (a formatter realigning the literal is enough). Unlike the two collisions above, this is a cheap `git rebase` for whichever PR lands second, not a design decision — note it when you present the wave rather than fixing the tracker to dodge it.

For the checks beyond these two — shared verification resources, discovery order, ticket
self-sufficiency, and edge justification — plus a worked example of each remedy, see
[`TICKET-SLICING.md`](TICKET-SLICING.md).

**Done when** every ticket you are about to fan out has no open blocker, and every ticket you are holding back carries an edge naming its blocker.

## 2. Cut a worktree per ticket

One worktree per ticket off the trunk, named `issue-<number>-<slug>` so its path traces back to the ticket:

```sh
wt switch --create issue-<n>-<slug> --base <trunk> --no-cd
```

`--no-cd` is the point: you are spawning siblings, not moving in. Run this repo's worktree hooks rather than reaching for `--yes` on your own judgement; the trust decision is the user's.

**Done when** `git worktree list` shows exactly one clean worktree per ticket, each on its own branch off the trunk.

## 3. Open an agent tab per worktree

In the repo's Rex session, per worktree: open a tab rooted at the worktree, label it with the branch name (`cleanup-branch` finds the tab by that label), launch the agent, and stage that ticket's `/implement`.

First make sure the repo's session exists. Look it up by label rather than trusting `$REX_SESSION`: this session may belong to another repo.

```sh
repo=<repo-name>   # the session label; use <owner>/<repo> if a session by this name is rooted at another repo
rex ls --json | jq -e --arg r "$repo" '.sessions[] | select(.label == $r)' >/dev/null \
  || rex new "$repo" -c <trunk-path> --window main
```

Then, per worktree:

```sh
created=$(rex window new -s "$repo" "<branch>" -c <worktree-path> --focus=false --json -- pi) || exit
agent=$(jq -er '.block_ids[0]' <<<"$created") || exit
until rex block call -s "$repo" -b "$agent" program_status | jq -e '.records[0].state == "idle"' >/dev/null; do sleep 0.5; done
rex send -s "$repo" -b "$agent" '/implement #<n>'     # no Enter, so it stays staged
```

Three rules make it reliable:

- **`--focus=false` on every tab.** This agent usually runs in the repo's own session, and a focused new tab would pull the user off it.
- **The agent is the tab's first pane, started directly (`-- pi`).** Target the `block_ids[0]` it returns.
- **`rex send` stages.** It types the text without Enter; the human's Enter starts the work.

The readiness signal is pi's own `program_status` going `idle`: pi reports it over OSC 7501 once its input box is up, so there is nothing to scrape. Cap the wait at about 30 seconds; past that, `rex capture -s "$repo" -b "$agent" --trim` and show the user what the pane holds instead of staging into it.

For a shell under the agent: `rex split -s "$repo" -b "$agent" --split=below --ratio 30 -c <worktree-path> --focus=false`. Shells, test runners and log tails are splits of the ticket's tab.

To show the user the first ticket, ask the app: `rex -C <client> do session.select session_id=<session> window_id=<tab-id>` (`rex client ls` lists clients; the tab's ID is `.window_id` from `window new`).

**Done when** each ticket has exactly one tab in the repo's session, labelled with its branch, with the agent idle at its worktree and `/implement #<n>` staged but unsubmitted. Leave the commands staged: the human pressing Enter in each tab is what starts the work, which keeps the fan-out itself from writing any code.

## Teardown

Tearing the worktrees down after their PRs merge is `cleanup-branch`'s job, one branch at a time — not a byproduct of the next fan-out.
