function k8s-context
    if test -n "$argv"
        set -f fzf_query "--query=$argv"
    end

    set -l context (kubectl config get-contexts -o name 2>/dev/null \
        | fzf --no-multi $fzf_query)

    if test -n "$context"
        kubectl config use-context $context
    end
end
