# Abbreviations and aliases

status is-interactive || exit

### Abbreviations ###
abbr --position anywhere acd "argocd --grpc-web"
abbr akcd "akuity argocd"

abbr b brew
abbr brewski "brew update && brew bundle && brew upgrade && brew autoremove && brew cleanup && brew doctor"

abbr bjson "bat -l json"
abbr byaml "bat -l yaml"

abbr calfix "launchctl stop com.apple.CalendarAgent && launchctl start com.apple.CalendarAgent"

abbr c chezmoi
abbr cadd "chezmoi add"
abbr capply "chezmoi apply --exclude=scripts"
abbr ccd "chezmoi cd"
abbr cdestroy "chezmoi destroy"
abbr cdiff "chezmoi diff"
abbr cedit "chezmoi edit --apply"
abbr creadd "chezmoi re-add"
abbr cstatus "chezmoi status"
abbr cupdate "chezmoi update"

abbr gbsu "git branch --set-upstream-to"
abbr gcae "git commit --allow-empty --verbose"
abbr gcae! "git commit --allow-empty --amend --verbose"
abbr gpdo "git push --delete origin"

abbr ghpr "gh pr create --fill"

abbr --position anywhere k kubectl
abbr --position anywhere ksys "kubectl --namespace=kube-system"
abbr kbuild "kustomize build --enable-alpha-plugins --enable-exec"
abbr kc k8s-context
abbr kdrain "kubectl drain --delete-emptydir-data --ignore-daemonsets"
abbr kfailed "kubectl delete pods -A --field-selector=status.phase=Failed"
abbr kkrew "kubectl krew"
abbr klogs "kubectl logs"
abbr kn k8s-namespace
abbr kport "kubectl port-forward"
abbr kwatch "watch kubectl"

abbr pc pbcopy
abbr pp pbpaste
abbr py python3

abbr reload "exec fish"
abbr tf terraform
abbr tfgp "terraform get -update && terraform plan"

### Aliases ###
function _alias
    command -q $argv[2] && alias $argv
end

_alias cat bat
_alias watch viddy

if command -q eza
    set -gx TREE_IGNORE "cache|log|logs"
    alias la "eza --all --git --group-directories-first --header --icons --long"
    alias ll "eza --git --group-directories-first --header --icons --long"
    alias ls "eza --git --group-directories-first --icons"
    alias lt "eza --group-directories-first --icons --ignore-glob=\"$TREE_IGNORE\" --level=2 --tree"
    alias tree "eza --group-directories-first --icons --ignore-glob=\"$TREE_IGNORE\" --tree"
end

alias less "less --force --no-init --hilite-search --ignore-case --SILENT --status-column --underline-special"
alias wget "wget --hsts-file=$XDG_CACHE_HOME/wget-hsts"
