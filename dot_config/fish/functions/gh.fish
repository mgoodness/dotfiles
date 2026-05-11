function gh --wraps=gh
    set GH_HOST
    if test \( "$argv[1]" = repo -a "$argv[2]" = clone \) -a -n "$argv[3]"
        switch (string split / "$argv[3]" | count)
            case 1
                set repo_dir "$GIT_WORKSPACE/github.com/mgoodness/$argv[3]"
            case 2
                if test ( string sub -l 4 "$argv[3]" ) = "mlb-"
                    set GH_HOST "emu.github.com"
                    set repo_dir "$GIT_WORKSPACE/$GH_HOST/$argv[3]"
                else
                    set repo_dir "$GIT_WORKSPACE/github.com/$argv[3]"
                end
            case 3
                set repo_dir "$GIT_WORKSPACE/$argv[3]"
        end

        mkdir -p $repo_dir
        cd $repo_dir/..
    end

    command gh $argv
end
