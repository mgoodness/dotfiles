function up --description "Update software to the latest version"
    argparse --stop-nonopt h/help auto -- $argv || return

    if set -q _flag_help
        __up_help
    else if set -q _flag_auto
        __up_auto
    else if not set -q argv[1]
        __up_all
    else if functions -q __up_$argv[1]
        __up_$argv[1] $argv[2..]
    else
        fish_log -e "Unknown command '$argv[1]'"
        return 1
    end
end

function __up_help --description "Print this help message"
    echo "\
Usage: up [options] command

  "(desc up)"

Options:
  -h, --help    "(desc __up_help)"
  --auto        "(desc __up_auto)"

Commands:"
    for cmd in (functions -a | string replace -rf "^__up_(?!all|auto|help)" "")
        printf "  %-13s %s\n" "$cmd" (desc __up_$cmd)
    end
end

function __up_auto --description "Update everything daily"
    status is-login && status is-interactive || return
    set -l file ~/.cache/fish/last-updated
    # Check if our last run was >1 day ago
    if [ -e "$file" ] && find "$file" -mtime +0 | not string match -q "$file"
        return
    end
    __up_all
    set -l fish (status fish-path)
    exec "$fish" -il
end

function __up_all --description "Update everything"
    test -e ~/.cache/fish || mkdir -p ~/.cache/fish
    touch ~/.cache/fish/last-updated
    for cmd in (functions -a | string replace -rf "^__up_(?!all|auto|docker|help)" "")
        echo (set_color blue)"dotfiles"(set_color normal): updating (set_color --bold)$cmd(set_color normal) >&2
        __up_$cmd
    end
end

function __up_homebrew --description "Update Homebrew packages"
    chezmoi apply --force ~/.config/homebrew

    # Brewfile is split shared/mlb/personal (gated per machine role); combine
    # whichever exist on this machine into one bundle for brew to operate on.
    set -lx HOMEBREW_BUNDLE_FILE (mktemp)
    cat ~/.config/homebrew/Brewfile ~/.config/homebrew/Brewfile.mlb ~/.config/homebrew/Brewfile.personal 2>/dev/null >$HOMEBREW_BUNDLE_FILE

    # `brew update -q` still prints a colored "==> Updating Homebrew..."
    # header even when already current; drop that one line.
    brew update -q 2>&1 | string match -r -v 'Updating Homebrew\.\.\.'
    brew bundle -q
    brew upgrade -q
    brew autoremove -q
    brew cleanup -q
    brew doctor -q

    # Sort the merged input the same way as the dump below, so delta only
    # shows real package differences instead of comment/grouping noise.
    set -l expected (mktemp)
    sort-brewfile $HOMEBREW_BUNDLE_FILE >$expected

    set -l actual (mktemp)
    brew bundle dump --force --file=$actual
    sort-brewfile -i $actual

    delta $expected $actual
    rm $HOMEBREW_BUNDLE_FILE $expected $actual
end

function __up_docker --description "Update Docker images"
    docker images --format '{{.Repository}}:{{.Tag}}' | xargs -n1 docker pull -q
    docker system prune -f
end

function __up_dotfiles --description "Update dotfiles"
    # `chezmoi update` shells out to `git pull`, which prints "Already up to
    # date." even on a no-op. Drop that one line, keep everything else (new
    # commits, apply output), and preserve chezmoi's exit status.
    chezmoi update --apply 2>&1 | string match -r -v '^Already up[- ]to[- ]date\.$'
    return $pipestatus[1]
end

function __up_fisher --description "Update fish packages"
    fisher update >/dev/null
    fish_update_completions &>/dev/null || true
end

function __up_gcloud --description "Update gcloud components"
    gcloud components update -q &>/dev/null
end

function __up_gh --description "Update gh extensions"
    gh extension upgrade --all >/dev/null
end

# function __up_git --description "Update git repos"
#     git workspace update &>/dev/null
#     env -u GIT_DIR -u GIT_WORK_TREE git workspace switch-and-pull &>/dev/null
#     git workspace run touch .envrc &>/dev/null
# end

function __up_pi --description "Update pi packages"
    pi update --all >/dev/null
end

function __up_herdr --description "Check for a herdr update and update its plugins"
    # Never run `herdr update` here — even with `--handoff` — because it
    # downloads and installs unconditionally once a newer release exists.
    # The instant the on-disk binary matches the latest release, `herdr
    # update --handoff` becomes a silent no-op ("already up to date") that
    # can no longer resync the still-running server: there's no dry-run
    # flag, and handoff only fires as part of an actual install. An
    # unattended run here would spend that one shot at a disruption-free
    # swap before a human ever gets to opt into `--handoff`, leaving only
    # the disruptive `herdr server stop` to resync afterward. So detection
    # is read-only: compare the installed client version against herdr's
    # public release manifest (the same one `herdr update` itself fetches)
    # and tell the human to run `herdr update --handoff` themselves, from a
    # shell that was never attached to herdr (HERDR_ENV unset) — `herdr
    # update` unconditionally refuses inside any herdr-spawned shell, since
    # every shell it spawns inherits HERDR_ENV. The manifest URL below only
    # covers the stable channel; preview builds use a different schema
    # (build_id/commit rather than a plain semver), so this stays silent on
    # preview and leaves detection to the restart_needed/server_binary_stale
    # check below.
    set -l status_json (herdr status --json 2>/dev/null | string collect)
    set -l installed (echo $status_json | jq -r '.client.version // empty')
    set -l server (echo $status_json | jq -r '.server.version // empty')
    set -l channel (herdr channel show 2>/dev/null)
    if test -n "$installed" -a "$channel" = stable
        set -l latest (curl -fsSL --max-time 5 https://herdr.dev/latest.json 2>/dev/null | jq -r '.version // empty')
        if test -n "$latest" -a "$latest" != "$installed"
            echo (set_color yellow)"dotfiles"(set_color normal)": herdr $latest available (have $installed) — run `herdr update --handoff` from a shell outside herdr" >&2
        end
    end

    # Covers the already-spent case: something (a manual `herdr update`, or
    # an older version of this script) already installed a newer binary
    # than the running server loaded. `--handoff` can't help anymore since
    # there's nothing left for it to install — only a full restart resyncs
    # the server at this point.
    if echo $status_json | jq -e '.update.restart_needed or .update.server_binary_stale' >/dev/null 2>&1
        echo (set_color yellow)"dotfiles"(set_color normal)": herdr $installed installed, but the server is still $server — run `herdr server stop` from a shell outside herdr" >&2
    end

    # A herdr upgrade can bump the bundled integration version, leaving the
    # installed Pi extension stale between chezmoi applies (the setup script
    # only re-checks it on the next apply); `--outdated-only` names exactly
    # the targets worth reinstalling and stays quiet when everything is
    # current.
    if herdr integration status --outdated-only 2>/dev/null | string match -q 'pi:*'
        echo (set_color blue)"dotfiles"(set_color normal): updating herdr pi integration >&2
        herdr integration install pi >/dev/null
    end

    for plugin in (herdr plugin list --json | jq -c '.result.plugins[] | select(.source.kind == "github")')
        set -l id (echo $plugin | jq -r '.source.owner + "/" + .source.repo')
        set -l enabled (echo $plugin | jq -r '.enabled')
        herdr plugin install $id --yes >/dev/null 2>&1
        test $enabled = false && herdr plugin disable $id >/dev/null 2>&1
    end
end

function __up_wt --description "Update worktrunk's Pi extension"
    # Unlike `herdr integration status`, worktrunk has no `plugins status`
    # probe, but `wt config plugins pi install` is content-aware: it rewrites
    # extensions/worktrunk.ts only when it differs from the bundled copy and
    # prints "already installed" otherwise. Running it unconditionally is
    # therefore a safe no-op that self-heals after a Homebrew `wt` upgrade.
    if not string match -q '*already installed*' -- (wt config plugins pi install -y 2>&1)
        echo (set_color blue)"dotfiles"(set_color normal): updating worktrunk pi extension >&2
    end
end

function __up_mas --description "Update macOS apps"
    mas outdated | grep -qvz " " || mas upgrade
end

function __up_macos --description "Update macOS"
    softwareupdate --list &| grep -q "No new" && return

    # SOFTWAREUPDATE_PASSWORD is role-gated in fnox's config (only one of the
    # personal/mlb 1Password accounts ever defines it per machine), and reads
    # through fnox's daemon cache instead of a bare `op read`.
    set -l password (fnox get SOFTWAREUPDATE_PASSWORD 2>/dev/null)
    if test -n "$password"
        echo $password | softwareupdate --all --install --stdinpass
    else
        softwareupdate --all --install
    end
end

function __up_rustup --description "Update Rust"
    rustup check &| grep -qvz available || rustup update
end

function __up_skills --description "Update agent skills"
    # Pinned so a `skills` release doesn't silently change apply behavior on
    # one machine before another. Bump deliberately, in lockstep with the
    # same pin in the two skills-install chezmoiscripts.
    set -l skills_version 1.7.0

    # `skills update` has no --json/structured-error mode (unlike `add` and
    # `remove` below), so — same as the old `gh skill update --all` — a
    # failure here is swallowed rather than surfaced. Not a regression, just
    # an upstream gap.
    npx --yes "skills@$skills_version" update -g -y &>/dev/null

    # mattpocock/skills has no top-level manifest the skills CLI (or gh
    # skill) can target as a unit — `add --skill` only accepts exact names,
    # never a directory prefix like skills/engineering — so keeping pace
    # with skills mattpocock adds, renames, or removes there means
    # rediscovering that list ourselves each run, rather than relying on a
    # hand-maintained list in agents.toml. (First install is bootstrapped
    # once per machine by
    # .chezmoiscripts/run_once_after_15-bootstrap-mattpocock-skills.sh;
    # this keeps it in sync afterward.)
    set -l repo mattpocock/skills
    set -l agents pi
    set -l names (
        for dir in engineering productivity
            gh api "repos/$repo/contents/skills/$dir" --jq '.[] | select(.type == "dir") | .name' 2>/dev/null
        end | sort -u
    )

    if test -z "$names"
        fish_log -w "dotfiles: could not reach $repo to sync its skills, skipping"
        return
    end

    # `skills update` (above) already diffs every already-installed skill's
    # tracked hash against its source and only re-fetches what changed
    # upstream. `skills add` has no such diffing, so only call it for names
    # genuinely missing from this machine. Installed-from-this-repo names
    # come straight from ~/.agents/.skill-lock.json — the lock file `gh
    # skill` and the `skills` CLI both read and write, keyed by name rather
    # than by name-and-agent, so one lookup covers every agent at once.
    # Lock keys for nested-path installs carry the discovery prefix (e.g.
    # "engineering/ask-matt"), but $names and the on-disk skill dirs are
    # bare ("ask-matt") — take just the last path segment to compare like
    # for like.
    set -l installed (jq -r --arg repo "$repo" '.skills | to_entries[] | select(.value.source == $repo) | .key | split("/")[-1]' ~/.agents/.skill-lock.json 2>/dev/null)
    set -l missing
    for name in $names
        contains -- $name $installed || set -a missing $name
    end

    if test (count $missing) -gt 0
        printf '%sdotfiles%s: installing %d new skill(s) from %s: %s\n' (set_color blue) (set_color normal) (count $missing) $repo (string join ', ' $missing) >&2
        if not set -l err (npx --yes "skills@$skills_version" add $repo --skill $missing --agent $agents -g -y --json 2>&1 1>/dev/null)
            printf '%s\n' $err >&2
        end
    end

    # Prune anything previously installed from this repo that's no longer in
    # the discovered set (renamed or removed upstream). `skills remove` is
    # lock-aware, unlike a bare `rm -rf` — it can't leave a stale lock entry
    # behind the way removing the directory by hand can.
    for name in $installed
        contains -- $name $names || npx --yes "skills@$skills_version" remove $name -g --agent $agents -y &>/dev/null
    end
end

# This self-discovery (also used by __up_help and __up_all above) relies on
# every __up_* function living in this one file: fish's `functions -a`
# finds autoload-eligible functions by scanning $fish_function_path for
# matching *filenames*, even before they've been sourced, so a function
# tucked inside a differently-named file (e.g. __up_herdr defined here in
# up.fish) is invisible to it until something has already triggered loading
# that file. Splitting a subcommand out is still safe *as long as its own
# file is named after it* (functions/__up_herdr.fish defining __up_herdr) —
# fish's directory scan will still find it unloaded. __up_herdr and
# __up_skills are the two candidates worth peeling out this way if they
# keep growing; the rest are one-liners not worth a file of their own.
# Remove any unfound items
for item in (functions -a | string replace -rf "^__up_(?!all|auto|help)" "")
    set -l cmd $item
    switch $item
        case docker
            set cmd docker podman
        case dotfiles
            set cmd chezmoi
        case fisher
            functions -q fisher || functions -e __up_$item
            continue
        case homebrew
            set cmd brew
        case macos
            set cmd softwareupdate
        case skills
            # command -q with multiple args is OR (any one suffices, as used
            # above for docker/podman) — skills needs gh *and* npx, so check
            # both explicitly instead of relying on that shared line below.
            command -q gh && command -q npx || functions -e __up_$item
            continue
    end
    command -q $cmd || functions -e __up_$item
end
