# Custom keybindings

status is-interactive || exit

bind ctrl-g 'gh pr view --web &>/dev/null || gh repo view --web &>/dev/null'

fzf_configure_bindings --directory=ctrl-f
