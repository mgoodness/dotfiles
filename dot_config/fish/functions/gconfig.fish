function gconfig
    if test -n "$argv"
        set -f fzf_query "--query=$argv"
    end

    set -l project (gcloud projects list --format='table(name,project_id)' | fzf --header-lines=1 --no-multi $fzf_query)

    if test -n $project
        set -l context $(string split ' ' -f1 $project)
        set -l contexts $(gcloud config configurations list --format='value(name)')
        if not contains $context $contexts
            gcloud config configurations create $context
        else
            gcloud config configurations activate $context
        end

        gcloud config set core/project $(string split ' ' -f2 -m1 -r $project)
        gcloud config set core/account michael.goodness@mlb.com
        gcloud config set compute/region us-central1
        gcloud config set compute/zone us-central1-a
    end
end
