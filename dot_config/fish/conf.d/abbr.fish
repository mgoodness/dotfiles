# Abbreviations and aliases

status is-interactive || exit

### Abbreviations ###
abbr b brew
abbr brewski "brew update && brew bundle && brew upgrade && brew cleanup && brew doctor"

abbr bjson "bat -l json"
abbr byaml "bat -l yaml"

abbr calfix "launchctl stop com.apple.CalendarAgent && launchctl start com.apple.CalendarAgent"
abbr gpgfix "gpgconf --kill gpg-agent"

abbr gbsu "git branch --set-upstream-to"
abbr gcae "git commit --allow-empty --verbose"
abbr gcae! "git commit --allow-empty --amend --verbose"
abbr gpdo "git push --delete origin"
# abbr grp git-rebase-preserve-author
# abbr grpm "git-rebase-preserve-author $(git_main_branch)"

# abbr gff "git-fresh -f"
abbr ghpr "gh pr create --fill"

abbr --position anywhere k kubectl
abbr --position anywhere ksys "kubectl --namespace=kube-system"
abbr kbuild "kustomize build"
abbr kc k8s-context
abbr kdrain "kubectl drain --delete-emptydir-data --ignore-daemonsets"
abbr kfailed "kubectl delete pods -A --field-selector=status.phase=Failed"
abbr kkrew "kubectl krew"
abbr klogs "kubectl logs"
abbr kn k8s-namespace
abbr kport "kubectl port-forward"
abbr kwatch "watch kubectl"

abbr p poetry
abbr pc pbcopy
abbr pp pbpaste
abbr py python3

# abbr sternsys "stern --namespace=kube-system"

abbr tf terraform
abbr tfgp "terraform get -update && terraform plan"

abbr urldecode "string unescape --style=url"
abbr urlencode "string escape --style=url"


### Aliases ###
function _alias
    command -q $argv[2] && alias $argv
end

_alias cat bat
_alias rm trash
_alias top glances
_alias watch viddy

if command -q exa
    set -gx TREE_IGNORE "cache|log|logs"
    alias la "exa --all --git --group-directories-first --header --icons --long"
    alias ll "exa --git --group-directories-first --header --icons --long"
    alias ls "exa --git --group-directories-first --icons"
    alias lt "exa --group-directories-first --icons --ignore-glob=\"$TREE_IGNORE\" --level=2 --tree"
    alias tree "exa --group-directories-first --icons --ignore-glob=\"$TREE_IGNORE\" --tree"
end

alias less "less --force --no-init --hilite-search --ignore-case --SILENT --status-column --underline-special"
