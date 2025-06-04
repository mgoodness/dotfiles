function gh --wraps=gh
    if test \( "$argv[1]" = repo -a "$argv[2]" = clone \) -a -n "$argv[3]"
        set repo_arg "$argv[3]"
        switch (string split / "$repo_arg" | count)
            case 1
                set repo_dir "$GIT_WORKSPACE/github.com/mgoodness/$repo_arg"
            case 2
                if test ( string sub -l 4 "$repo_arg" ) = "mlb-"
                    set argv[3] "emu.github.com/$repo_arg"
                    set repo_dir "$GIT_WORKSPACE/emu.github.com/$repo_arg"
                else
                    set repo_dir "$GIT_WORKSPACE/github.com/$repo_arg"
                end
            case 3
                set repo_dir "$GIT_WORKSPACE/$argv[3]"
        end

        mkdir -p $repo_dir
        cd $repo_dir/..
    end

    command gh $argv
end
