function mdpick --description "Fuzzy-find a Markdown file under DIR (default .) and render it with mdcat"
    # mdcat's own `mdpick` binary alias (argv[0] == "mdpick") does this natively,
    # but that requires an actual symlink to the mdcat binary — argv[0] can't be
    # spoofed through a plain fish abbr/alias, and there's no --pick flag. This
    # reimplements the same documented behavior (fuzzy-find a Markdown file below
    # DIR, render the pick) as a fish function instead, so no extra symlink
    # management is needed.
    set -l dir .
    test -n "$argv[1]" && set dir $argv[1]

    set -l file (find $dir -type f \( -iname '*.md' -o -iname '*.markdown' \) 2>/dev/null | sort | fzf --prompt='mdpick> ' --preview 'mdcat --no-pager --columns "$FZF_PREVIEW_COLUMNS" {}' --preview-window=right:60%)

    test -n "$file" && mdcat $file
end
