function new-gke
    if test -n "$argv"
        set -f fzf_query "--query=$argv"
    end

    set -l cluster (gcloud container clusters list --format='table(name,zone)' | fzf --header-lines=1 --no-multi $fzf_query)

    if test -n "$cluster"
        gcloud container clusters get-credentials \
            "$(printf $cluster | cut -f1 -d' ')" \
            --region=(printf $cluster | tr -s ' ' | cut -f2 -d' ')
    end
end
