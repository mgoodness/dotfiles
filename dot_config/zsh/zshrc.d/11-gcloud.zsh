USE_GKE_GCLOUD_AUTH_PLUGIN=True

source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"

alias gcontext=gcloud-context
alias new-gcontext=new-gcloud-context

[[ "$(alias gke)" ]] && unalias gke

## Lazy-load the completion function for gcloud & gsutil.
# Ref: https://github.com/marlonrichert/zsh-snap/issues/128#issuecomment-961414817
znap function _python_argcomplete gcloud gsutil \
    'eval "$( register-python-argcomplete gcloud gsutil )"'

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
