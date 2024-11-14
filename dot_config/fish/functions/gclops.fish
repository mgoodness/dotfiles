function gclops
    if test -n "$argv"
        set -f fzf_query "--query=$argv"
    end

    set -l project (gcloud projects list --format='table(name,project_id)' | fzf --header-lines=1 --no-multi $fzf_query)

    if test -n $project
        gcloud container operations list \
          --project="$(string split ' ' -f2 -n $project)" \
          --format="table(NAME,TYPE,LOCATION,TARGET,STATUS_MESSAGE,STATUS,START_TIME,END_TIME)"
    end
end
