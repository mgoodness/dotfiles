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
        printf "  %-13""s %s\n" $cmd (desc __up_$cmd)
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
    for cmd in (functions -a | string replace -rf "^__up_(?!all|auto|help)" "")
        echo (set_color blue)"dotfiles"(set_color normal): updating (set_color --bold)$cmd(set_color normal) >&2
        __up_$cmd
    end
end

function __up_homebrew --description "Update Homebrew packages"
    brew upgrade
    brew autoremove
    brew cleanup
    brew doctor
end

function __up_dotfiles --description "Update dotfiles"
    # Update repo
    chezmoi update

    # Update package lists
    # command -q brew && brew bundle dump --force --no-restart
    # cat $HOMEBREW_BUNDLE_FILE | string replace -r '("qlmarkdown"|"syntax-highlight")$' '$1, args: { no_quarantine: true }' >$HOMEBREW_BUNDLE_FILE
    # command -q code && code --list-extensions >$XDG_CONFIG_HOME/code/extensions.txt

    # Trash non-xdg cache
    command rm -rf ~/.{bash_history,bundle,config/configstore,kube,lesshst,node,npm,rustup,yarnrc}
end

function __up_fisher --description "Update fish packages"
    fisher update >/dev/null
    fish_update_completions >/dev/null
end

function __up_gcloud --description "Update gcloud"
    gcloud components update -q &>/dev/null
end

function __up_mas --description "Update macOS apps"
    mas outdated | grep -q " " && mas upgrade
end

# function __up_macos --description "Update macOS"
#     softwareupdate --list &| grep -q "No new" || softwareupdate --install --all
# end

# Remove any unfound items
for item in (functions -a | string replace -rf "^__up_(?!all|auto|help)" "")
    set -l cmd $item
    switch $item
        case dotfiles
            set cmd chezmoi
        case fisher
            set cmd fish
        case homebrew
            set cmd brew
        case macos
            set cmd softwareupdate
    end
    command -q $cmd || functions -e __up_$item
end
