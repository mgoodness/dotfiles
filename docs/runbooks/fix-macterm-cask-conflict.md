# Fixing the macterm cask's merge-conflict markers

`brew bundle` / `brew install` fails with:

```
Warning: Cask 'macterm' is unreadable: …/Taps/thdxg/homebrew-tap/Casks/macterm.rb:24: syntax errors found
Error: Cask 'macterm' is unreadable: …/Taps/thdxg/homebrew-tap/Casks/macterm.rb:24: syntax errors found
```

The tap's cask file has literal git merge-conflict markers (`<<<<<<<`, `|||||||`,
`=======`, `>>>>>>>`) left in it, so Ruby can't parse the cask and Homebrew treats it as
unreadable. Run this once per machine that hits the symptom.

## Background

Homebrew's `brew update` auto-stashes any uncommitted changes in a tap, rebases onto
`origin/main`, then pops the stash. If upstream changed the same lines, the pop conflicts
and leaves the markers in the working tree. Here the local edit converted the
quarantine-stripping step from `postflight`/`system_command` to
`postflight_steps`/`run` (see the comment in the cask), and upstream landed the same
conversion via [PR #5](https://github.com/thdxg/homebrew-tap/pull/5) — but kept
`sudo: false`. The local copy is therefore redundant and strictly worse (it would make
the `xattr` call prompt for a password), so the fix is to take upstream and drop the
stale stash.

## 0. Confirm the symptom

```sh
brew info --cask macterm
```

Expect the `syntax errors found` message above. If it parses cleanly, this machine is
already fixed — stop.

## 1. Inspect the tap

```sh
cd "$(brew --repo thdxg/homebrew-tap)"
git status
git stash list
```

Expect `Unmerged paths: both modified: Casks/macterm.rb` and a `stash@{0}` entry. If the
tap has never been tapped on this machine, `brew --repo` fails and this runbook doesn't
apply — just install fresh (see step 4).

## 2. Confirm the stash is the redundant edit

```sh
git stash show -p 'stash@{0}'
git show HEAD:Casks/macterm.rb | sed -n '20,35p'
```

Expect the stash diff to touch only `Casks/macterm.rb`, swapping the old
`postflight`/`system_command` step for `postflight_steps`/`run`, while `HEAD` already has
the same `postflight_steps` block **including** `sudo: false`.

If the stash contains anything else — another file, or a local-only intent you actually
want — **stop and resolve by hand**: take upstream, then re-apply the real local change as
a commit (or upstream it). Do not blindly discard it.

## 3. Resolve to upstream and clear the stash

```sh
git checkout HEAD -- Casks/macterm.rb
git add Casks/macterm.rb
git stash drop 'stash@{0}'
git status        # expect: nothing to commit, working tree clean
```

No commit is needed — the resolved file is byte-identical to `HEAD`.

## 4. Verify

```sh
brew info --cask macterm              # expect: parses, prints the version, no syntax warning
brew install macterm                  # expect: installs, or "latest version already installed"
brew list --cask --versions macterm   # expect: macterm <version>
```

## Preventing recurrence

Uncommitted edits inside a Homebrew tap are fragile: every `brew update` re-stashes them
and re-pops them against upstream, so the same conflict can keep coming back. A durable
fix belongs upstreamed as a PR to `thdxg/homebrew-tap`. As of this writing the
`postflight_steps` conversion is already upstream, so there is nothing left to reapply —
the only step is clearing the stale local state above.
