function gh --wraps=gh
    set --function clone_host # only set for mlb- clones; overrides GH_HOST for this call only
    set --function repo_dir # empty unless this is a clone; gates the herdr register below
    set --function orig_pwd $PWD # cloning temporarily cd's; restore this before returning
    if test \( "$argv[1]" = repo -a "$argv[2]" = clone \) -a -n "$argv[3]"
        # Normalize full URLs (https://.../owner/repo, git@host:owner/repo) down to the
        # same [host/]owner/repo shorthand the switch below already understands.
        set --function spec (string replace -r '\.git$' '' -- "$argv[3]")
        set --function was_url false

        if string match -qr '^https?://' -- "$spec"
            set spec (string replace -r '^https?://' '' -- "$spec")
            set spec (string trim -r -c / -- "$spec")
            set was_url true
        else if string match -qr '^git@' -- "$spec"
            set spec (string replace -r '^git@' '' -- "$spec")
            set spec (string replace ':' '/' -- "$spec")
            set spec (string trim -r -c / -- "$spec")
            set was_url true
        end

        # A URL/SSH remote on the default host doesn't need the host segment; dropping it
        # lets the owner-based emu.github.com routing below apply as usual.
        if test "$was_url" = true
            set --function spec_parts (string split / -- "$spec")
            if test (count $spec_parts) = 3 -a "$spec_parts[1]" = github.com
                set spec "$spec_parts[2]/$spec_parts[3]"
            end
        end

        switch (string split / "$spec" | count)
            case 1
                set repo_dir "$GIT_WORKSPACE/github.com/mgoodness/$spec"
            case 2
                set --function owner (string split / "$spec")[1]
                if string match -q 'mlb-*' -- "$owner"; or test "$owner" = Michael-Goodness_mlb
                    set clone_host "emu.github.com"
                    set repo_dir "$GIT_WORKSPACE/$clone_host/$spec"
                else
                    set repo_dir "$GIT_WORKSPACE/github.com/$spec"
                end
            case 3
                set repo_dir "$GIT_WORKSPACE/$spec"
        end

        mkdir -p $repo_dir
        cd $repo_dir/..
        set argv[3] $spec
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

    if set --query repo_dir[1]
        cd $orig_pwd
    end

    return $gh_status
end
