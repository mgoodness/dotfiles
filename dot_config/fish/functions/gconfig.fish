function gconfig
    if test -n "$argv"
        set -f fzf_query "--query=$argv"
    end

    set -l context (gcloud config configurations list --format='value(name)' | fzf --no-multi $fzf_query)

    if test -n "$context"
        gcloud config configurations activate "$context"
    end
end
