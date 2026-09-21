# Does Macterm cover herdr's functionality enough to justify dropping herdr?

**Question:** PR #44 ("chore: remove herdr") drops herdr's chezmoi-managed footprint. The
maintainer's stated reason is that Macterm "provides enough similar functionality" to
justify the switch. This note verifies that claim, feature by feature, against primary
sources.

**Bottom line up front:** **Partially supported, with two real, plainly-named gaps.**
Macterm is a solid Ghostty-based terminal with a genuine CLI/automation surface and
matches herdr almost exactly on desktop notifications and reasonably on session
persistence. But it has **zero native concept of a coding agent** (no `agent`
subcommand, no lifecycle/status API, no idle/working/blocked/done classification) and
**zero concept of a git worktree** (no `worktree` verb anywhere, `project create` is not
idempotent per path, and there is no documented non-focus-stealing way to open a project
in the background). Those two gaps are exactly the two things this repo actually used
herdr for: `spin-up-worktrees`'s nested-workspace-per-worktree mechanism and
`cleanup-branch`'s live-agent check before deleting a worktree — both skills were deleted
outright in PR #44 with no replacement, which the PR body itself flags as unresolved.

Sources consulted: `herdr` binary `--help` (installed locally, v0.9.1 per its own docs
index), herdr.dev's documentation index and `docs/next/website/src/content/docs/*.mdx`
pages fetched at the `v0.9.1` tag from `github.com/herdrdev/herdr`, `macterm --help` /
`macterm help <subcommand>` (installed locally via `brew install --cask
thdxg/tap/macterm`), Macterm's `README.md` (raw, `main` branch), Macterm's docs site
(`macterm.thdxg.dev/docs/cli`, `/docs/shortcuts`), and Macterm's GitHub PRs #19, #298,
#300 and Discussions #217–219 (via `gh api`/`gh pr view`). This repo's own git history
(`chore/remove-herdr` branch, commit `fa0440f` = branch point, `8af66e1` = ADR-0006
commit) was used to recover the pre-removal content of `CONTEXT.md`,
`dot_config/worktrunk/config.toml`, `.chezmoiscripts/run_after_17-herdr-setup.sh`,
`dot_agents/skills/{spin-up-worktrees,cleanup-branch}/SKILL.md`, and the current draft
`docs/adr/0006-drop-herdr.md` and PR #44 body.

---

## 1. Workspace/pane/tab management nested per git worktree

**herdr:** This is herdr's core mechanic. `herdr --help` lists a dedicated
`herdr worktree <subcommand>` command group (`list`, `create`, `open`, `remove`) —
"Git worktree helpers over the socket API." `herdr worktree open --help` shows
`--path <PATH>`, `--focus`/`--no-focus`, and no required parent-workspace hint. This
repo's pre-removal `dot_config/worktrunk/config.toml` (`git show fa0440f:...`) called it
directly from worktrunk's `post-start` hook:

```
herdr = 'herdr worktree open --path "{{ worktree_path }}" --label "{{ branch }}" --no-focus'
```

with an inline comment: "`--path` alone is enough for herdr to nest this under the right
parent — it reads repo identity off the worktree's own git metadata... which matters
here since a hook only ever knows the worktree path, not which workspace triggered it."
The pre-removal `CONTEXT.md` (`git show fa0440f:CONTEXT.md`) confirms: "Worktree-backed
workspaces nest automatically under any other open workspace on the same repo (matched
by `repo_key`...) — no manual grouping step." The pre-removal `spin-up-worktrees`
SKILL.md also documents that `herdr worktree open` is **idempotent per path** — a second
call at the same path returns `already_open: true` naming the same workspace rather than
creating a duplicate.

**Macterm:** `macterm --help` lists `project`, `tab`, `pane`, `window`, `grid`,
`session`, `layout` — no `worktree` noun. A repo-wide search of Macterm's docs site
(`/docs/cli`, `/docs/configuration`) for the literal string "worktree" returns zero
matches. The closest primitive is `macterm project create <path> [--name N] [--select]`.
Per Macterm's own CLI docs (`macterm.thdxg.dev/docs/cli`): **"Not idempotent — each run
adds a distinct project."** This is the opposite of herdr's guarantee that
`spin-up-worktrees` explicitly relies on to avoid duplicate workspaces from a racing
`post-start` hook.

On focus-stealing: neither `macterm --help project create` nor `macterm --help window
new` documents a background/no-focus flag (only `--select`, `--name`, `--json`,
`--socket`). Macterm's Shortcuts/App-Intents doc (`/docs/shortcuts`) describes the
equivalent "New Project" action as: **"Adds a folder as a project, selects it, and
brings the window forward. ... Always creates a new project, even if one already backs
that folder."** So the one primitive that plays the same role as `herdr worktree open`
(1) is not path-idempotent and (2) is documented, in its Shortcuts form, as bringing the
window forward — the opposite of `--no-focus`. Macterm has no notion of "parent"
workspace/repo grouping at all; `project list` is a flat list.

**Verdict: does not cover this.** Macterm has no git-worktree concept, no idempotent
open-by-path, and no documented way to open a project non-interactively without
front-ing the window — the three properties worktrunk's `post-start` hook actually
depends on.

## 2. Native per-pane agent tracking

**herdr:** `herdr --help` lists a dedicated `herdr agent <subcommand>` group (`list`,
`get`, `read`, `send-keys`, `prompt`, `rename`, `focus`, `wait`, `attach`, `start`,
`explain`). herdr's `concepts.mdx` defines five agent states (`blocked`, `working`,
`done`, `idle`, `unknown`) and states "Each client tracks which completions it has
displayed... CLI/API statuses use the server's seen state." `agents.mdx` documents a
table of ~20 natively-recognized agents (Pi, Claude Code, Codex, etc.), a two-tier
detection model (lifecycle-hook integrations as authoritative state source when
installed, else screen-manifest heuristics), and a custom-reporting API:
`herdr pane report-agent w1:p1 --source custom:indexer --agent docs-bot --state working`.
The socket API doc lists `pane.report_agent`, `pane.report_agent_session`,
`pane.release_agent` as first-class raw methods. This repo had (per the deleted
`~/.pi/agent/extensions/herdr-agent-state.ts`, referenced in the PR #44 body and
AGENTS.md's now-removed herdr section) a Pi extension pushing state over
`HERDR_SOCKET_PATH` for exactly this reason.

**Macterm:** `macterm --help` has no `agent` noun at all — the full top-level list is
`status, project, tab, window, pane, grid, session, layout, tutor, ssh`. `macterm pane
list` reports "session names, cwd, foreground process, and execution state" (per
`/docs/cli`), and `macterm pane inspect` reports a raw `foreground 79497 (nvim
src/main.rs)` field — i.e., Macterm knows the OS-level foreground process name and PID
in a pane, the same low tier herdr's screen-manifest fallback starts from. But there is
no state classification, no lifecycle-hook/report API, no wait-until-state primitive,
and no rollup to tab/project (herdr's "a blocked agent makes its pane, tab, and workspace
look blocked" sidebar behavior, per `agents.mdx`, has no Macterm analogue). `gh api
search/code -f q="plugin repo:thdxg/macterm"` and discussion search turned up nothing
resembling an agent-state API either (see §3).

**Verdict: does not cover this.** Macterm exposes only the same raw ingredient
(foreground process name) that is the _bottom_ of herdr's two-tier agent-detection
system — it has none of the classification, lifecycle-hook API, wait/notify, or
sidebar-rollup layer above it.

## 3. A worktree-lifecycle plugin/binding

**herdr:** herdr has a documented plugin system (`plugins.mdx`): "Herdr plugins are
shareable, executable workflow packages... A plugin is a directory with a
`herdr-plugin.toml` manifest," supporting `[[actions]]`, `[[events]]` (e.g. `on =
"worktree.created"`), `[[panes]]`, `[[link_handlers]]`, installed via `herdr plugin
install <owner>/<repo>`. This repo's pre-removal
`.chezmoiscripts/run_after_17-herdr-setup.sh` (`git show fa0440f:...`) installed
`devashish2203/herdr-worktrunk` via exactly this mechanism, and pre-removal ADR-0004
(`git show fa0440f:docs/adr/0004-one-agent-per-worktree.md`) states: "Herdr's worktrunk
plugin binds `prefix+shift+g` / `prefix+shift+c` to switch or create a Worktree."

**Macterm:** No plugin system exists in any primary source checked. Macterm's README
lists its extension surfaces as: a "Control CLI" (the `macterm` binary), a "Command
palette," "Declarative layouts" (YAML files describing tabs/splits/commands for one
project, applied via `macterm layout apply`), and App Intents for Shortcuts/Spotlight/
Siri (`/docs/shortcuts`). None of these is a plugin architecture: layouts are static,
per-project descriptions with no event-hook or manifest concept, and App Intents are
Apple's own automation surface, not something Macterm defines or lets third parties
extend with new subcommands. `gh api search/code -f q="plugin repo:thdxg/macterm"`
returned 3 hits (checked: incidental uses of the word, not a plugin subsystem — no
`plugin` noun appears in `macterm --help`). A GraphQL discussion search
(`gh api graphql`) over all of Macterm's Discussions found none about plugins; the
closest are Discussions #217–219, which are all Cookbook _recipes_ (shell scripts /
keybind configs), not an extension mechanism.

**Verdict: does not cover this.** No plugin system, therefore nothing that could bind a
key to worktrunk's switch/create/remove the way `herdr-worktrunk` did.

## 4. Scriptable CLI/automation surface

**herdr:** The `herdr` skill (referenced by name in the deleted `spin-up-worktrees` and
`cleanup-branch` skills) wraps the CLI/socket API documented in `socket-api.mdx` and
`agent-automation.mdx`: create/list/focus/rename/close workspaces and tabs; split,
swap, focus, resize, rename, read, close, send input to panes; list/inspect/read/
prompt/wait-on/rename/focus/start/attach agents; report custom agent state; subscribe
to events. The pre-removal `cleanup-branch` SKILL.md (`git show fa0440f:...`) used this
concretely to detect a **live agent before deleting a worktree**:

```sh
herdr worktree list | jq -r --arg p "<path>" '.result.worktrees[] | select(.path==$p) | .open_workspace_id'
herdr pane list --workspace <workspace-id>
```

"Any pane carrying an `agent` field is a live agent — any value counts... regardless of
`agent_status`."

**Macterm:** `macterm --help` and `macterm help <subcommand>` (run locally) expose
`status`, `project {list,create,select,rename,remove}`, `tab {list,new,select,move,
rename,close}`, `window {list,new,focus,close}`, `pane {list,inspect,dump,split,mirror,
focus,close,run,key,zoom,resize-split}`, `grid <RxC>`, `session {list,info,kill}`,
`layout {apply,save}`, `tutor`, `ssh`. Every verb takes `--json` and `--socket` (per
`/docs/cli`), and there's a documented raw JSON-over-Unix-socket wire protocol
(`~/Library/Application Support/Macterm/control.sock`) plus a published Cookbook
Claude-skill recipe (Discussion #219) built on `pane run` (type text) / `pane dump`
(read terminal cells) / `pane key` (send a chord) for driving interactive programs from
a script or agent. This is a real, comparable scripting surface for panes/tabs/projects.

But there is **no agent-detection verb to reuse for the "is something live in this
pane" check** `cleanup-branch` needs. `macterm pane list`'s "foreground process" field
(name + PID) is the only signal available — it would tell you a shell's foreground
process is `claude` or `pi`, but Macterm defines no `agent` field, no `agent_status`,
and no documented convention distinguishing "a live coding-agent process" from any
other foreground process a user might have running (`vim`, `npm run dev`, etc.). A
`cleanup-branch`-style rewrite against Macterm would have to invent and hard-code its
own agent-name matching against `pane list`'s foreground-process field — nothing in
Macterm's CLI does this classification today.

**Verdict: partially covers this.** The pane/tab/project scripting surface itself is
comparable in spirit (JSON output, socket protocol, "type + read the screen" recipe for
interactive programs). The specific "detect a live agent before deleting a worktree"
capability `cleanup-branch` used has no equivalent — see §2 and §7.

## 5. Desktop notifications

**herdr / Macterm:** Already well-established in this repo per commit `709d741`
(`feat(pi): add desktop-notify extension for Ghostty/Macterm OSC 777 notifications`,
already in this repo, predating PR #44). Confirmed against primary sources:

- **PR #19** (`thdxg/macterm`, merged): adds OSC 777 (`GHOSTTY_ACTION_DESKTOP_NOTIFICATION`)
  and command-finish notifications, tagged by pane/project for click-to-navigate,
  suppressed when the source pane is focused.
- **PR #298**: "Match Ghostty and standard macOS app behavior by playing the default
  system sound for notifications."
- **PR #300**: adds a per-pane subtitle (`pane.displayTitle`), auto-clears delivered
  notifications on pane refocus/destroy, adds a "Show" action, and makes a banner
  swipe-dismiss not navigate.

This is a Ghostty-inherited feature (Macterm is Ghostty-derived, per the task's own
framing and Macterm's README: "Built on libghostty... Ghostty compatibility: Reads your
existing Ghostty config"), so it is not herdr-specific functionality either — herdr,
running inside a Ghostty-family terminal, would get the same underlying OSC 777
forwarding. Confirmed still accurate.

**Verdict: covers this.**

## 6. Session persistence

**herdr:** `persistence-remote.mdx` describes a client/server split: `ctrl+b q` detaches
a client, the server (and its panes/agents) keeps running; `herdr server stop` ends it.
`session-state.mdx` documents four graduated cases (detach/reattach, server restart,
update without/with `--handoff`) with a table of what survives each — including
**pane screen-history replay** (opt-in, `[experimental] pane_history = true`, because
"pane output can include secrets, tokens, prompts, and command output") and **native
agent session restore** keyed to per-agent resume commands (e.g. `claude --resume <id>`,
`pi --session <path-or-id>`) for ~15 integrated agents when herdr's own integration is
installed for that agent.

**Macterm:** README: "**Session persistence** Quitting detaches your shells instead of
killing them; relaunching brings them back with scrollback and running processes
intact," backed by `macterm session {list,info,kill}` over what the docs call
"zmx-backed terminal sessions" (`/docs/cli`: "zmx sessions with attached-pane
mapping"). README also separately claims **"Remote projects — Open a directory on
another machine over SSH. Your shells keep running there, surviving quits, dropped
connections, and even a local reboot,"** which is a genuinely stronger persistence
claim in the _host-side_ dimension than anything documented for herdr's own SSH story
(herdr's `--remote` and "saved machines" mode instead runs the server on the remote
host and streams to a local client — comparable directionally, not identical
mechanics; not fully compared here since it wasn't the question's focus).

Macterm's `layout apply`/`layout save` (declarative YAML per project) is roughly
analogous to herdr's snapshot-restore ("workspaces, tabs, panes, cwd, layout, and
focus" reconstructed after a server restart) but is an explicit save/apply step, not an
automatic continuous one — no equivalent of herdr's opt-in pane-history replay or its
native per-agent conversation-resume table was found in Macterm's docs or `--help`
output.

**Verdict: partially covers this.** The base claim (quit ≠ kill, shells and scrollback
survive) is comparable and independently confirmed (zmx-backed sessions vs. herdr's
persistent server). Herdr's more elaborate restore machinery — opt-in screen-history
replay and native per-agent session resume across ~15 integrations — has no documented
Macterm counterpart, but this repo's ADRs and skills never actually depended on that
finer-grained machinery, so this gap is unlikely to matter in practice.

## 7. Things herdr does that Macterm has no equivalent for at all

Stated plainly, as real gaps (not just found/not-found noise):

1. **Git-worktree awareness.** herdr has a first-class `worktree` object
   (list/create/open/remove, `repo_key`-based auto-nesting, idempotent-by-path open).
   Macterm has no `worktree` noun anywhere in its CLI or docs. This is the literal
   mechanism `dot_config/worktrunk/config.toml`'s `post-start` hook and the deleted
   `spin-up-worktrees` skill were built on.
2. **Agent lifecycle state.** herdr classifies each pane's occupant into
   `idle`/`working`/`blocked`/`done`/`unknown`, rolls that up to tab/workspace, exposes
   `agent wait`/`agent prompt`/`agent explain`, and lets integrations report state via a
   documented hook API. Macterm has no `agent` noun, no state classification beyond a
   raw foreground-process name/PID, and no lifecycle-report API.
3. **A plugin system.** herdr has a manifest-driven plugin architecture
   (`herdr-plugin.toml`: actions, event hooks, panes, link handlers) that a third party
   (`devashish2203/herdr-worktrunk`) used to bind keys directly to worktrunk's
   switch/create/remove. Macterm has no plugin system in any source checked (README,
   docs site, `--help`, GitHub search/discussions) — only static YAML layouts, a
   command palette, and Apple's App Intents for Shortcuts/Spotlight/Siri.
4. **Idempotent, non-focus-stealing "open at path."** herdr's `worktree open --path ... --no-focus` is documented to no-op safely into `already_open: true` when called
   twice at the same path, and to not steal window focus. Macterm's nearest analogue,
   `project create`, is documented as **not** idempotent ("each run adds a distinct
   project") and has no `--no-focus`/background flag; its App-Intents twin is
   documented to bring the window forward every time.

These four gaps map directly onto what PR #44 itself flags as consequences with **no
replacement**: "The `spin-up-worktrees` homegrown skill is deleted outright... nothing
salvageable remains once herdr is gone" and "`cleanup-branch`'s herdr-workspace teardown
step is dropped too, which removes a safety check it relied on (confirming no live agent
was still running in a worktree's directory before deleting it) — there is currently no
replacement for that check." Both statements are corroborated, not merely repeated,
by the primary-source comparison above.

---

## Overall verdict

**Partially supported, with named gaps.** The maintainer's claim holds cleanly for one
dimension this repo actually used (desktop notifications, §5 — a wash, since both
inherit it from Ghostty) and reasonably for another (session persistence, §6 — base
claim comparable, finer machinery unused by this repo anyway). It does **not** hold for
the two dimensions this repo built real automation on: git-worktree-aware,
idempotent, background-safe workspace opening (§1, §7.1/§7.4) and native per-pane agent
tracking with a lifecycle API (§2, §7.2) — plus the plugin system that let a third
party wire worktrunk bindings into the UI at all (§3, §7.3). Concretely, dropping herdr
for Macterm alone means:

- No automatic "open this new worktree in its own nested window/tab, without stealing
  focus" step — worktrunk's `post-start` hook has nothing to call that behaves the same
  way Macterm's `project create` does today.
- No safety check for "is an agent still running in this worktree" before `wt remove`
  deletes it — `cleanup-branch`'s dropped step has no drop-in replacement using
  Macterm's CLI, because Macterm's `pane list` only reports a raw foreground-process
  name, not a classified agent state.
- No worktree-lifecycle keybindings analogous to `herdr-worktrunk`'s `prefix+shift+g/c/d`,
  because Macterm has no plugin system to hang them on.

These are the same gaps PR #44's own body already names as open questions ("Judgment
calls worth a second look before merging," items 2–3) — this research confirms, against
Macterm's primary sources, that they are real and not merely hypothetical, and that no
part of Macterm's documented feature set closes them today.
