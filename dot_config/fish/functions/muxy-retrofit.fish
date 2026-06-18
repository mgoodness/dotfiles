function muxy-retrofit --description "Backfill .muxy/layouts symlinks into existing Muxy worktrees"
    set --local layouts ~/.config/muxy/layouts
    if not test -d $layouts
        echo "muxy-retrofit: $layouts not found (run chezmoi apply first)" >&2
        return 1
    end

    set --local linked 0
    # Iterate every registered Muxy project, then each of its worktrees.
    for project in (muxy list-projects)
        set --local proj_path (string split \t -- $project)[3]

        for worktree in (muxy list-worktrees "$proj_path")
            set --local wtp (string split \t -- $worktree)[3]

            # Skip the Home/$HOME project and anything that isn't a git
            # working tree (rev-parse covers both main and linked worktrees).
            test "$wtp" = "$HOME"; and continue
            git -C "$wtp" rev-parse --is-inside-work-tree &>/dev/null; or continue

            mkdir -p "$wtp/.muxy"
            ln -sfn $layouts "$wtp/.muxy/layouts"
            echo "linked $wtp/.muxy/layouts"
            set linked (math $linked + 1)
        end
    end

    echo "muxy-retrofit: linked layouts into $linked worktree(s)"
end
