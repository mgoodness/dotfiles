# Which ~/Code tree the current directory is under: emu, ghes, personal, or
# nothing. EMU is the default `gh` identity on an MLB machine, so only ghes and
# personal need a different one.
function __gh_tree_for_pwd
    test -n "$GIT_WORKSPACE"; or return 0
    switch "$PWD/"
        case "$GIT_WORKSPACE/emu.github.com/*"
            echo emu
        case "$GIT_WORKSPACE/github.mlbam.net/*"
            echo ghes
        case "$GIT_WORKSPACE/github.com/*"
            echo personal
    end
end
