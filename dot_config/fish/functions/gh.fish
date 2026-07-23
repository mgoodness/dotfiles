function gh --wraps=gh
    set --function clone_host # only set for mlb- clones; overrides GH_HOST for this call only
    set --function repo_dir # empty unless this is a clone; gates the herdr register below
    if test \( "$argv[1]" = repo -a "$argv[2]" = clone \) -a -n "$argv[3]"
        switch (string split / "$argv[3]" | count)
            case 1
                set repo_dir "$GIT_WORKSPACE/github.com/mgoodness/$argv[3]"
            case 2
                if test ( string sub -l 4 "$argv[3]" ) = mlb-
                    set clone_host "emu.github.com"
                    set repo_dir "$GIT_WORKSPACE/$clone_host/$argv[3]"
                else
                    set repo_dir "$GIT_WORKSPACE/github.com/$argv[3]"
                end
            case 3
                set repo_dir "$GIT_WORKSPACE/$argv[3]"
        end

        mkdir -p $repo_dir
        cd $repo_dir/..
    end

    if set --query clone_host[1]
        GH_HOST=$clone_host command gh $argv
    else
        command gh $argv
    end
    set --local gh_status $status

    # Open a freshly cloned repo as a focused herdr workspace. Env prep is manual
    # for clones — run `mise install` when you start work (the worktrunk hook
    # handles worktrees).
    if set --query repo_dir[1]; and test $gh_status -eq 0
        herdr workspace create --cwd $repo_dir --focus
    end

    return $gh_status
end
