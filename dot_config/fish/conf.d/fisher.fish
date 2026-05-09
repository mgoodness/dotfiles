# Fisher: https://github.com/jorgebucaran/fisher

# Install
if not functions -q fisher && status is-login
    curl -sL git.io/fisher | source && fisher update >/dev/null
    printf 11121112y | COLUMNS=55 LINES=21 tide configure
end

# Source conf.d snippets
for file in $fisher_path/conf.d/*.fish
    builtin source $file 2>/dev/null
end
