# Ref: https://github.com/marlonrichert/.config/blob/main/zsh/zshrc.d/05-completion.zsh
# Ref: https://github.com/Aloxaf/fzf-tab/wiki/Configuration

##
# Completion config
#

# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Preview file contents
# https://github.com/Aloxaf/fzf-tab/wiki/Preview#show-file-contents

# Use Enter to select & execute
zstyle ':fzf-tab:*' accept-line enter

# Use spacebar to select & continue editing
zstyle ':fzf-tab:*' fzf-bindings 'space:accept'

# Switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# Preview environment variables
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
    fzf-preview 'echo ${(P)word}'

# Preview directory content with exa when completing `cd`
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'

# Preview git commands
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
    'git diff $word | delta'|
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
    'case "$group" in
    "modified file") git diff $word | delta ;;
    "recent commit object name") git show --color=always $word | delta ;;
    *) git log --color=always $word ;;
    esac'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview \
    'git help $word | bat -plman --color=always'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
    'git log --color=always $word'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
    'case "$group" in
    "commit tag") git show --color=always $word ;;
    *) git show --color=always $word | delta ;;
    esac'

# Preview command line arguments when completing `kill` and `ps`
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
    '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

# Preview systemd unit status when completing `systemctl`
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# Auto-installed by Brew, but far worse than the one supplied by Zsh
rm -f $HOMEBREW_PREFIX/share/zsh/site-functions/_git{,.zwc}

znap fpath _chezmoi 'chezmoi completion zsh'
znap fpath _pdm 'pdm completion zsh'
znap fpath _poetry  'poetry completions zsh'

# Set up lazy loading for pipx completions
znap function _python_argcomplete pipx  'eval "$( register-python-argcomplete pipx  )"'
complete -o nospace -o default -o bashdefault \
           -F _python_argcomplete pipx

## Lazy-load the completion function for gcloud & gsutil.
# Ref: https://github.com/marlonrichert/zsh-snap/issues/128#issuecomment-961414817
znap function _python_argcomplete gloud gsutil \
    'eval "$( register-python-argcomplete gloud gsutil )"'

# Cache command output.
bqinit() {
  unfunction bqinit
  typeset -gH BQ_COMMANDS="$(
      CLOUDSDK_COMPONENT_MANAGER_DISABLE_UPDATE_CHECK=1 bq help |
          grep '^[^ ][^ ]*  ' |
          sed 's/ .*//'
  )"
  typeset -m BQ_COMMANDS
}
znap eval bq bqinit

# Define custom, bash-style completion function.
_bq() {
    set -- $COMP_LINE
    shift
    while [[ $1 == -* ]]; do
          shift
    done
    [[ -n "$2" ]] &&
        return
    grep -q 'bq\s*$' <<< $COMP_LINE &&
        COMPREPLY=( $BQ_COMMANDS ) &&
        return
    [[ "$COMP_LINE" == *' ' ]] &&
        return
    [[ -n "$1" ]] &&
        COMPREPLY=( $( echo "$BQ_COMMANDS" | grep ^"$1" ) )
}

# Register bash-style completions.
complete -o nospace -o default -F _python_argcomplete gcloud
complete -o nospace -F _python_argcomplete gsutil
complete -o default -F _bq bq
