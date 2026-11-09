function rx --description 'Open a new Rex session in a directory (path, zoxide query, or fzf pick) and switch to it'
    set -l dir
    if test (count $argv) -eq 0
        set dir (zoxide query --interactive) # fzf picker over frecent dirs
    else if test -d "$argv[1]"
        set dir (path resolve $argv[1])
    else
        set dir (zoxide query -- $argv) # fuzzy match, e.g. `rx dotfiles`
    end

    if test -z "$dir"; or not test -d "$dir"
        echo "rx: no directory for: $argv" >&2
        return 1
    end

    set -l id (rex session new (path basename $dir) --cwd $dir --json | jq -er .session_id)
    or return

    # Switch the Rex app to it (the new session isn't shown automatically)
    rex do session.select session_id=$id >/dev/null
end
