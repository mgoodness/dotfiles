function gh --wraps=gh
    set --function tree # emu, ghes, personal, or empty; see __gh_tree_for_owner/_pwd
    set --function repo_dir # empty unless this is a clone; gates the cd-restore below
    set --function orig_pwd $PWD # cloning temporarily cd's; restore this before returning
    if test "$argv[1]" = repo
        and test "$argv[2]" = clone
        and test -n "$argv[3]"
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
        # lets the owner-based routing below apply as usual.
        if test "$was_url" = true
            set --function spec_parts (string split / -- "$spec")
            if test (count $spec_parts) = 3 -a "$spec_parts[1]" = github.com
                set spec "$spec_parts[2]/$spec_parts[3]"
            end
        end

        if test -z "$GIT_WORKSPACE"
            echo "gh: GIT_WORKSPACE is not set" >&2
            return 1
        end

        set --function parts (string split / -- "$spec")
        switch (count $parts)
            case 1
                set tree personal
                set repo_dir "$GIT_WORKSPACE/github.com/mgoodness/$spec"
            case 2
                set tree (__gh_tree_for_owner $parts[1])
            case 3
                # emu.github.com/<org>/<repo> is an explicit EMU override: it is a
                # directory name, not a real host, so gh gets plain <org>/<repo>.
                # github.mlbam.net/<org>/<repo> is a real host and goes to gh as typed.
                switch $parts[1]
                    case emu.github.com
                        set tree emu
                        set spec "$parts[2]/$parts[3]"
                        set repo_dir "$GIT_WORKSPACE/emu.github.com/$spec"
                    case github.mlbam.net
                        set tree ghes
                        set repo_dir "$GIT_WORKSPACE/$spec"
                    case '*'
                        set repo_dir "$GIT_WORKSPACE/$spec"
                end
        end

        if test -z "$repo_dir"
            switch $tree
                case emu
                    set repo_dir "$GIT_WORKSPACE/emu.github.com/$spec"
                case ghes
                    set repo_dir "$GIT_WORKSPACE/github.mlbam.net/$spec"
                case '*'
                    set repo_dir "$GIT_WORKSPACE/github.com/$spec"
            end
        end

        # Run gh only from inside the destination tree: a failed mkdir/cd must not
        # clone into whatever directory this was called from.
        if not mkdir -p $repo_dir; or not cd $repo_dir/..
            echo "gh: cannot enter $repo_dir/.." >&2
            cd $orig_pwd
            return 1
        end
        set argv[3] $spec
    else if not contains -- "$argv[1]" auth extension ext
        # Any other command follows the tree it runs in. gh auth and gh extension
        # manage gh itself, so a token override would only confuse them.
        set tree (__gh_tree_for_pwd)
    end

    # Plain gh is the default identity (EMU on an MLB machine, personal elsewhere),
    # so only the other trees need a wrapper. gh-ghes and gh-personal carry the host
    # and token for their tree; no command relies on mise's directory hook
    # swapping GH_TOKEN after a cd. gh-personal exists on MLB machines only.
    switch "$tree"
        case ghes
            gh-ghes $argv
        case personal
            if command -q gh-personal
                gh-personal $argv
            else
                command gh $argv
            end
        case '*'
            command gh $argv
    end
    set --local gh_status $status

    # Env prep is manual for clones — run `mise install` when you start work
    # (the worktrunk hook handles worktrees).
    if set --query repo_dir[1]
        cd $orig_pwd
    end

    return $gh_status
end
