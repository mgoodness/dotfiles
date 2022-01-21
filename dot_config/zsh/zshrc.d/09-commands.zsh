# Ref: https://github.com/marlonrichert/.config/blob/main/zsh/zshrc.d/08-commands.zsh

##
# Commands, aliases & functions
#

# znap source marlonrichert/zsh-hist  # History editing tools

alias \
    diff='diff --color' \
    grep='grep --color' \
    make='make -j' \
    {\$,%}=  # For pasting command line examples

# File type associations
alias -s \
    gz='gzip -l' \
    {gradle,json,md,patch,properties,txt,xml,yml}=$PAGER
if [[ $VENDOR == apple ]]; then
  alias -s \
      {log,out}='open -a Console'
else
  alias -s \
      {log,out}='code' \
      deb='deb'
  deb() {
    sudo apt install "$@[1,-2]" "$@[-1]:P"
  }
fi

# Pattern matching support for `cp`, `ln` and `mv`
# See http://zsh.sourceforge.net/Doc/Release/User-Contributions.html#index-zmv
# Tip: Use -n for no execution. (Print what would happen, but don’t do it.)
autoload -Uz zmv
alias \
    zmv='zmv -v' \
    zcp='zmv -Cv' \
    zln='zmv -Lv'

# Paging & colors for `ls`
# ls() {
#   command ${${OSTYPE:#linux-gnu}:+g}ls --width=$COLUMNS "$@" | $PAGER
#   return $pipestatus[1]  # Return exit status of ls, not $PAGER
# }
# zstyle ':completion:*:ls:*:options' ignored-patterns --width
# alias \
#     ls='ls --group-directories-first --color -AFvx'

# Safer alternatives to `rm`
if [[ $VENDOR == apple ]]; then
  trash() {
    local -aU items=( $^@(N) )
    local -aU missing=( ${@:|items} )
    (( $#missing )) &&
        print -u2 "trash: no such file(s): $missing"
    (( $#items )) ||
        return 66
    print Moving $( eval ls -d -- ${(q)items[@]%/} ) to Trash.
    items=( '(POSIX file "'${^items[@]:a}'")' )
    osascript -e 'tell application "Finder" to delete every item of {'${(j:, :)items}'}' \
        > /dev/null
  }
elif command -v gio > /dev/null; then
  # gio is available for macOS, but gio trash DOES NOT WORK correctly there.
  alias \
      trash='gio trash'
fi

alias bjson='bat -l json'
alias byaml='bat -l yaml'

alias -g brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
alias brewski='brew update && \
  brew bundle --global && \
  brew upgrade &&
  brew cleanup && \
  brew doctor'

alias dockerclean='docker system prune --all'

alias gcontext=gcloud-context
alias new-gcontext=new-gcloud-context

alias gbsu='git branch --set-upstream-to'
alias gcae='git commit --allow-empty --verbose'
alias gcae!='git commit --allow-empty --amend --verbose'
alias gff='git-fresh -f'
alias gpdo='git push --delete origin'
alias grp=git-rebase-preserve-author
alias grpm='git-rebase-preserve-author $(git_main_branch)'
alias gshow='git show --decorate'

alias ghpr='gh pr create --fill'
alias ghprco='gh pr checkout'

[[ "$(alias gke)" ]] && unalias gke

alias gpgpfix='gpgconf --kill gpg-agent'

alias k=kubectl
alias kbuild='kustomize build'
alias kc=kube-context
alias kclean=kube-clean-contexts
alias kdrain='kubectl drain --delete-emptydir-data --ignore-daemonsets'
alias kkrew='kubectl krew'
alias klogs='kubectl logs'
alias kn=kube-namespace
alias kport='kubectl port-forward'
alias -g ksys='kubectl --namespace=kube-system'
alias kwatch='watch kubectl'

alias less='less --force --no-init --hilite-search --ignore-case \
  --SILENT --status-column --underline-special'

alias ll='exa -all --git --group-directories-first --long'
alias ls='exa --all --group-directories-first'
alias lt="exa --ignore-glob=\"$TREE_IGNORE\" --level=2 --only-dirs --tree"
alias tree="exa --group-directories-first --ignore-glob=\"$TREE_IGNORE\" --tree"

alias sternsys='stern --namespace=kube-system'

alias tf=terraform
alias tfgp='terraform get --update && terraform plan'

alias watch='watch '
