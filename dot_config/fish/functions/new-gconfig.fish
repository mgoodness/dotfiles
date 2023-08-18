function new-gconfig
    if test -n "$argv"
        set -f fzf_query "--query=$argv"
    end

    set -l project (gcloud projects list --format='table(name,project_id)' | fzf --header-lines=1 --no-multi $fzf_query)

    if test -n "$project"
        gcloud config configurations create "$(printf $project | cut -f1 -d' ')"
        gcloud config set core/project "$(printf $project | tr -s ' ' | cut -f2 -d' ')"
        gcloud config set core/account michael.goodness@mlb.com
        gcloud config set compute/region us-central1
        gcloud config set compute/zone us-central1-a
    end
end
