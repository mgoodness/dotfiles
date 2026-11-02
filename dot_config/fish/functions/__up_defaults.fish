function __up_defaults --description "Report macOS/app settings that drift from .chezmoidata/defaults.toml"
    # Compares live `defaults` settings against the declared ones
    # ([defaults."<domain>"] tables in .chezmoidata/defaults.toml) and reports the
    # difference, staying silent when everything matches;
    # it never writes. Domains listed under [defaultsDiscover] are also scanned
    # for undeclared keys (minus their `ignore` globs), so a change made in an
    # app's UI surfaces with a paste-ready entry. Only top-level scalar values
    # (bool, number, string) are compared; dicts, data and dates are skipped.
    #
    # Lives in its own file, named after the function, so up.fish's
    # `functions -a` self-discovery still finds it before it's loaded.
    command -q defaults && command -q plutil && command -q chezmoi && command -q jq || return 0

    set -l data (chezmoi data --format json | string collect) || return

    set -l decl_domains
    set -l decl_keys
    set -l decl_vals
    for line in (printf %s $data | jq -r '(.defaults // {}) | to_entries[] | .key as $d | .value | to_entries[] | [$d, .key, (.value | tostring)] | @tsv')
        set -l f (string split \t -- $line)
        set -a decl_domains $f[1]
        set -a decl_keys $f[2]
        set -a decl_vals $f[3]
    end

    set -l domains (printf %s $data | jq -r '(((.defaults // {}) | keys) + ((.defaultsDiscover // {}) | keys)) | unique[]')

    set -l drift 0
    set -l snippet
    set -l snippet_domains
    for domain in $domains
        set -l plist (defaults export $domain - 2>/dev/null | plutil -p - 2>/dev/null)

        # Top-level scalar entries only: `  "key" => true|false|<number>|"string"`.
        set -l live_keys
        set -l live_vals
        set -l live_types
        for line in $plist
            set -l m (string match -rg '^  "(.+?)" => (true|false|-?\d+(?:\.\d+)?|".*")$' -- $line)
            test (count $m) -eq 2 || continue
            set -l key $m[1]
            set -l val $m[2]
            set -l type string
            switch $val
                case true false
                    set type bool
                case '"*'
                    set val (string sub -s 2 -e -1 -- $val)
                case '*.*'
                    set type float
                case '*'
                    set type int
            end
            set -a live_keys $key
            set -a live_vals $val
            set -a live_types $type
        end

        # A domain with no settings at all means the app has never run here
        # (e.g. Rex isn't installed on this machine), not that they all drifted.
        if not set -q live_keys[1]
            fish_log -w "dotfiles: no '$domain' settings found, skipping"
            continue
        end

        set -l dom_keys
        for i in (seq (count $decl_keys))
            test "$decl_domains[$i]" = "$domain" || continue
            set -a dom_keys $decl_keys[$i]
            set -l idx (contains -i -- $decl_keys[$i] $live_keys)
            if test -z "$idx"
                printf '%s- %s %s%s: declared %s, not set\n' (set_color red) $domain $decl_keys[$i] (set_color normal) $decl_vals[$i] >&2
                set drift 1
            else if test "$live_vals[$idx]" != "$decl_vals[$i]"
                printf '%s~ %s %s%s: declared %s, live %s\n' (set_color yellow) $domain $decl_keys[$i] (set_color normal) $decl_vals[$i] $live_vals[$idx] >&2
                set drift 1
            end
        end

        printf %s $data | jq -e --arg d $domain '.defaultsDiscover[$d]' >/dev/null 2>&1 || continue
        set -l ignore (printf %s $data | jq -r --arg d $domain '.defaultsDiscover[$d].ignore[]?')

        for i in (seq (count $live_keys))
            contains -- $live_keys[$i] $dom_keys && continue
            set -l skip 0
            for pat in $ignore
                if string match -q -- $pat $live_keys[$i]
                    set skip 1
                    break
                end
            end
            test $skip -eq 1 && continue

            printf '%s+ %s %s%s = %s\n' (set_color green) $domain $live_keys[$i] (set_color normal) $live_vals[$i] >&2
            set drift 1
            # plutil -p prints a float like 12.0 as "12", so ask `defaults` for
            # the real type rather than trusting the guess made while parsing.
            set -l type $live_types[$i]
            switch (defaults read-type $domain $live_keys[$i] 2>/dev/null)
                case '*boolean'
                    set type bool
                case '*integer'
                    set type int
                case '*float'
                    set type float
                case '*string'
                    set type string
            end
            set -l tv $live_vals[$i]
            test $type = string && set tv '"'$tv'"'
            # TOML types a float by its decimal point; plutil drops it from 12.0.
            test $type = float && not string match -q '*.*' -- $tv && set tv $tv.0
            contains -- $domain $snippet_domains || begin
                set -a snippet "[defaults.\"$domain\"]"
                set -a snippet_domains $domain
            end
            set -a snippet "\"$live_keys[$i]\" = $tv"
        end
    end

    test $drift -eq 0 && return 0

    if set -q snippet[1]
        echo >&2
        echo "Add to .chezmoidata/defaults.toml, under the domain's existing table, to adopt the new settings (or add a glob to that domain's ignore list):" >&2
        printf '%s\n' $snippet >&2
    end
    echo "Edit .chezmoidata/defaults.toml (chezmoi cd) to adopt a changed value; 'chezmoi apply' re-applies the declared ones." >&2
    return 1
end
