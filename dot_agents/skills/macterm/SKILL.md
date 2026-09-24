---
name: macterm
description: Control the Macterm terminal emulator from the command line — run commands in panes, read what a pane is displaying (including full-screen TUIs that produce no pipeable output), create tabs, splits, and projects, and manage persistent sessions. Use whenever the user asks to run something in a Macterm pane, inspect what a terminal is showing, drive an interactive program, or set up a Macterm workspace/tabs/project layout.
---

# Macterm control CLI

`macterm` drives a running Macterm over a Unix socket. Same-user only.

## Reaching it

- **Inside a Macterm pane**: `macterm` is already on `PATH`, and `$MACTERM_SESSION`
  is that pane's own session — so a bare `macterm pane split` self-targets.
- **Outside** (e.g. a sandboxed agent shell): run
  `/Applications/Macterm.app/Contents/Resources/bin/macterm`. It discovers the
  socket itself; pass `--socket <path>` only to pin a specific install (e.g. a
  debug build alongside a release one).
- **`Connection refused` while `ps`/`lsof` show Macterm running and holding
  an fd on the socket path**: the app's control-socket listener died inside
  the process while the UI stayed up — not a sandboxing artifact, and not
  fixed by retrying, `--socket`, or a different shell (confirm with a raw
  connect, e.g. `python3 -c "import socket; socket.socket(socket.AF_UNIX).connect('<path>')"`,
  to rule out a caller-side sandbox before concluding this). The fix is to quit
  and relaunch Macterm (`osascript -e 'tell application "Macterm" to quit'`,
  then `open -a Macterm`) so it rebinds a live listener. Terminal sessions are
  `zmx`-backed and restart-stable, so a relaunch reconnects the GUI to running
  sessions rather than killing them.

Exit codes: `0` success, `1` Macterm reported an error, `2` couldn't reach it.
Nothing goes to stdout unless the command succeeded. Every verb takes `--json`.

## Verbs

|                                                        |                                                                          |
| ------------------------------------------------------ | ------------------------------------------------------------------------ |
| `project list/create/select/rename/remove`             | Projects — one per repo/directory; `create <path>` is idempotent by path |
| `window list/new/focus/close`                          | Terminal windows                                                         |
| `tab list/new/select/move/rename/close`                | Tabs; `tab new --run CMD` spawns a command                               |
| `pane list`                                            | Panes with session names, cwd, foreground process, focus marker          |
| `pane dump [--scrollback]`                             | What the pane is displaying — the observation channel                    |
| `pane run <text>`                                      | Paste text plus a newline into a live pane's shell or REPL               |
| `pane key <chord>`                                     | One encoded keypress: `ctrl+c`, `ctrl+d`, `escape`, `up`                 |
| `pane split [--direction right\|left\|down\|up\|auto]` | Split a pane                                                             |
| `pane mirror`                                          | Show the same session in a second pane                                   |
| `pane focus`, `pane zoom`, `pane close`                | Focus, zoom, close                                                       |
| `grid RxC`                                             | Split into an equal grid (≤16 cells), e.g. `2x2`                         |
| `session list/info/kill`                               | The zmx sessions backing panes                                           |
| `layout apply/save`                                    | Reconcile or capture a project's declarative layout file                 |

Full flags for any verb: `macterm help <verb> [<subcommand>]`.

## Rules

**Target explicitly.** `--pane pane:2` is the 1-based index within the active
tab. `--session macterm-…` is restart-stable — pane UUIDs regenerate every
launch, session names don't. Read both from `pane list`. Both resolve inside
the **active project**; pass `--project <name>` to target a tab in any other,
or the command answers "no pane in this project runs session …". With no
selector, `pane run`/`pane key` target the current pane via
`$MACTERM_SESSION` — only meaningful when the caller is itself inside a
Macterm pane.

**`pane run` pastes text, `pane key` sends a key event — they aren't
interchangeable.** `pane run` submits with a trailing newline by default;
`--no-submit` leaves the text on the prompt unsubmitted (pre-filling a command
for a human, or feeding a TUI that submits on its own terms) — follow up with
`macterm pane key return` to execute it as a real submission. Reach for
`pane key` instead of typed text when you need an actual key _event_ a control
byte (`ctrl+c`) or a named key (`escape`, `up`) that no pasted text can
express.

**Wrap redirects in `/bin/sh -c '…'`.** Typed text lands in the _user's_
shell, and shells disagree: in nushell `>` is a comparison operator, so a
bare `echo ok > /tmp/done` silently writes no file.

**Wait for a sentinel, never a sleep.** There is no reliable "is it finished"
signal to poll:

```sh
rm -f /tmp/done
macterm pane run --pane pane:2 "/bin/sh -c 'make test; echo ok > /tmp/done'"
until [ -f /tmp/done ]; do sleep 0.5; done
macterm pane dump --pane pane:2 | tail -20
```

If you poll the screen instead, remember the line you typed is echoed there —
assemble the marker at runtime (`printf done-%s $NONCE`) so the joined string
only ever appears in real output.

**A `busy` error means ask the user, not retry with `--force`.** Forcing a
close kills that pane's session and whatever was running in it. Close verbs
always require an explicit target.

**`pane resize` is debug-only, and its failure is misleading.** A release CLI
has no `resize` subcommand, so it falls through to `pane`'s default (`list`)
and reports `Unexpected argument 'resize'` under a `pane list` usage line —
nothing about the real cause. Use `pane resize-split --axis <horizontal|vertical>
--ratio <0.15–0.85>` instead, which exists in every build.
