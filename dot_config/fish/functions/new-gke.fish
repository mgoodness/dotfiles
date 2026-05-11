function new-gke
    gconfig $argv

    set -l cluster (gcloud container clusters list --format='table(name,zone)' | fzf --header-lines=1 --no-multi)

    if test -n "$cluster"
        gcloud container clusters get-credentials \
            "$(printf $cluster | cut -f1 -d' ')" \
            --region=(printf $cluster | tr -s ' ' | cut -f2 -d' ')
    end
end
