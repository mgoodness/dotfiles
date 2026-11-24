# Which ~/Code tree an owner's repos belong in: emu, ghes, or personal.
# The directory layout is the source of truth (it already selects each tree's
# SSH key and git identity), so an owner with a directory in a tree belongs to
# that tree. An owner with no directory yet falls back to a guess: where an
# emu.github.com tree exists (MLB machines), github.com means EMU and only
# the personal account is personal; elsewhere everything is personal.
function __gh_tree_for_owner --argument-names owner
    set --local trees emu:emu.github.com ghes:github.mlbam.net personal:github.com
    for tree in $trees
        set --local parts (string split : -- $tree)
        if test -d "$GIT_WORKSPACE/$parts[2]/$owner"
            echo $parts[1]
            return
        end
    end

    if test -d "$GIT_WORKSPACE/emu.github.com"; and not string match -qi mgoodness -- $owner
        echo emu
    else
        echo personal
    end
end
