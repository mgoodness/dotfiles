function gh --wraps=gh
    if test \( "$argv[1]" = repo -a "$argv[2]" = clone \) -a -n "$argv[3]"
        switch (string split / "$argv[3]" | count)
            case 1
                set repo_dir "$GIT_WORKSPACE/github.com/mgoodness/$argv[3]"
            case 2
                set org_repo "$argv[3]"
                if test ( string sub -l 4 "$org_repo" ) = "mlb-"
                    set repo_dir "$GIT_WORKSPACE/emu.github.com/$org_repo"
                else
                    set repo_dir "$GIT_WORKSPACE/github.com/$org_repo"
                end
            case 3
                set repo_dir "$GIT_WORKSPACE/$argv[3]"
        end

        mkdir -p $repo_dir
        cd $repo_dir/..
    end

    command gh $argv
end
