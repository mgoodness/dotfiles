functions -q __fish_git || source $__fish_data_dir/completions/git.fish
complete -c git -n '__fish_seen_subcommand_from finishpr' \
    -a '(__fish_git_local_branches)' -f
