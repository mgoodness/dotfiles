function sort-brewfile --description "Sort Brewfile entries by section, alphabetically within each section"
    argparse h/help i/in-place -- $argv || return

    if set -q _flag_help
        echo "Usage: sort-brewfile [-i] [brewfile]"
        echo ""
        echo "Sort Brewfile entries by section, alphabetically within each section."
        echo "The tap section is placed first; sections are separated by blank lines."
        echo ""
        echo "Options:"
        echo "  -h, --help      Show this help"
        echo "  -i, --in-place  Edit the file in place"
        return 0
    end

    set -l brewfile ~/.config/homebrew/Brewfile
    if test (count $argv) -gt 0
        set brewfile $argv[1]
    end

    if not test -f "$brewfile"
        fish_log -e "Brewfile not found: $brewfile"
        return 1
    end

    set -l lines (cat -- $brewfile)

    set -l found_sections
    for line in $lines
        test -z "$line" && continue
        string match -q '#*' "$line" && continue
        set -l section (string split ' ' -- $line)[1]
        contains $section $found_sections || set -a found_sections $section
    end

    set -l section_order tap
    for s in (printf '%s\n' $found_sections | sort)
        test "$s" = tap && continue
        set -a section_order $s
    end

    set -l output_lines
    set -l section_count 0

    for section in $section_order
        contains $section $found_sections || continue

        set -l section_lines
        for line in $lines
            test -z "$line" && continue
            string match -q '#*' "$line" && continue
            test (string split ' ' -- $line)[1] = $section && set -a section_lines $line
        end

        test (count $section_lines) -eq 0 && continue

        if test $section_count -gt 0
            set -a output_lines ""
        end
        set section_count (math $section_count + 1)

        for line in (string join \n -- $section_lines | sort)
            set -a output_lines $line
        end
    end

    if set -q _flag_in_place
        printf '%s\n' $output_lines >$brewfile
    else
        printf '%s\n' $output_lines
    end
end
