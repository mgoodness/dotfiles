# Custom keybindings

status is-interactive || exit

bind \cc 'commandline ""'
bind \cg 'gh pr view --web &>/dev/null || gh repo view --web &>/dev/null'

fzf_configure_bindings --directory=\cf
