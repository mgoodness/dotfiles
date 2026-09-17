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

    brew update -q
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
    chezmoi update --apply
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

function __up_herdr --description "Update herdr and its plugins"
    # `herdr update` refuses unconditionally while attached to a session
    # (this shell always is, since the daemon persists) with a precondition
    # error mentioning "outside herdr" — that message says nothing about
    # whether a real update exists, so it can't be used as a signal. Only a
    # genuine "not updated" decline (from herdr's interactive
    # replace-running-server confirmation, defaulted to no via blank stdin)
    # or a real pending-restart flag from `herdr status` mean anything.
    set -l update_msg (herdr update </dev/null 2>&1)
    if string match -qr 'not updated' -- $update_msg
        if set -q HERDR_ENV
            echo (set_color yellow)"dotfiles"(set_color normal): herdr update available — run \`herdr update\` after detaching >&2
        else
            echo (set_color yellow)"dotfiles"(set_color normal): herdr update available — run \`herdr update\` to install it >&2
        end
    else if herdr status --json 2>/dev/null | jq -e '.update.restart_needed or .update.server_binary_stale' >/dev/null 2>&1
        echo (set_color yellow)"dotfiles"(set_color normal): herdr update installed — restart the session to pick it up >&2
    end

    # A herdr upgrade can bump the bundled integration version, leaving the
    # installed Pi extension stale. The setup script only guards claude (a
    # `herdr integration status | grep` check), so pi would otherwise go
    # stale silently; `--outdated-only` names exactly the targets worth
    # reinstalling and stays quiet when everything is current.
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

    # secrets.mlb.yaml/secrets.personal.yaml only exist per machine role;
    # read the matching account's admin password for non-interactive install.
    if test -f ~/.config/fish/secrets.mlb.yaml
        op read --account mlb.1password.com "op://Employee/Okta/password" | softwareupdate --all --install --stdinpass
    else if test -f ~/.config/fish/secrets.personal.yaml
        op read --account my.1password.com "op://Private/Mac mini/password" | softwareupdate --all --install --stdinpass
    else
        softwareupdate --all --install
    end
end

function __up_rustup --description "Update Rust"
    rustup check &| grep -qvz available || rustup update
end

function __up_skills --description "Update agent skills"
    echo (set_color blue)"dotfiles"(set_color normal): checking installed skills for updates >&2
    gh skill update --all &>/dev/null

    # mattpocock/skills has no top-level manifest gh skill (or npx skills)
    # can target as a unit — gh skill install only accepts a single skill
    # name or exact SKILL.md path, never a directory prefix like
    # skills/engineering — so keeping pace with skills mattpocock adds,
    # renames, or removes there means rediscovering that list ourselves
    # each run, rather than relying on a hand-maintained list in
    # agents.toml. (First install is bootstrapped once per machine by
    # .chezmoiscripts/run_once_after_15-bootstrap-mattpocock-skills.sh;
    # this keeps it in sync afterward.)
    set -l repo mattpocock/skills
    set -l agents claude-code universal
    set -l names (
        for dir in engineering productivity
            gh api "repos/$repo/contents/skills/$dir" --jq '.[] | select(.type == "dir") | .name' 2>/dev/null
        end | sort -u
    )

    if test -z "$names"
        fish_log -w "dotfiles: could not reach $repo to sync its skills, skipping"
        return
    end

    # gh skill update --all (above) already diffs every already-installed
    # skill's tracked tree SHA against its remote repo and only re-downloads
    # what actually changed upstream — cheap, a repo-level check rather than
    # one round trip per skill. gh skill install has no such diffing (-f
    # always re-downloads), so only call it for names genuinely missing from
    # this machine; everything already present is update's job, not ours.
    set -l source_url "https://github.com/$repo"
    for agent in $agents
        set -l installed (gh skill list --agent $agent --scope user --json sourceURL,path 2>/dev/null | jq -r --arg url "$source_url" '.[] | select(.sourceURL == $url) | .path' | xargs -n1 basename)
        set -l missing
        for name in $names
            contains -- $name $installed || set -a missing $name
        end

        if test (count $missing) -gt 0
            set -l total (count $missing)
            set -l done 0
            for name in $missing
                set done (math $done + 1)
                printf '\r\033[K%sdotfiles%s: installing new skill %s — %s (%s) [%d/%d]' (set_color blue) (set_color normal) $repo $name $agent $done $total >&2
                if not set -l err (gh skill install $repo $name --agent $agent --scope user -f 2>&1 1>/dev/null)
                    printf '\n%s\n' $err >&2
                end
            end
            printf '\r\033[K' >&2
        end
    end

    # Prune anything gh skill previously installed from this repo that's no
    # longer in the discovered set (renamed or removed upstream).
    for path in (gh skill list --scope user --json sourceURL,path 2>/dev/null | jq -r --arg url "$source_url" '.[] | select(.sourceURL == $url) | .path')
        set -l name (basename $path)
        contains -- $name $names || rm -rf -- $path
    end
end

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
            set cmd gh
    end
    command -q $cmd || functions -e __up_$item
end
