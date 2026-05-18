# Custom keybindings

status is-interactive || exit

bind -M default ctrl-g 'gh pr view --web &>/dev/null || gh repo view --web &>/dev/null'
bind -M insert ctrl-g 'gh pr view --web &>/dev/null || gh repo view --web &>/dev/null'

bind -M default ctrl-z 'fg 2>/dev/null; commandline -f repaint'
bind -M insert ctrl-z 'fg 2>/dev/null; commandline -f repaint'

fzf_configure_bindings --directory=ctrl-f
