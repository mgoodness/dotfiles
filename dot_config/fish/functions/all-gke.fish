function all-gke
    for file in $(fd -e yml 'mlb-\w{3}-\d' $argv)
        set -l cluster_id (yq .metadata.labels.cluster $file)
        set -l ballpark (yq .metadata.labels.ballpark $file)

        set -l name ()
        gcloud --project=mlb-ballparks-prod-ae8c container fleet memberships get-credentials mlb-ballpark-prod-$ballpark-cluster$cluster_id
    end

    for file in $(fd -e yml -E "*pci*" gcp $argv)
        set -l cluster

        set -l cluster_id (yq .metadata.labels.cluster $file)
        set -l name (yq .metadata.name $file)
        set -l project (yq .metadata.labels.gcp-project $file)
        set -l region (yq .metadata.labels.region $file)

        set -l clusters (gcloud --format='table[no-heading](name,zone)' --project=$project container clusters --region=$region list)
        if test (count $clusters) -eq 1
            set cluster (printf $clusters | cut -f1 -d' ')
        else
            set cluster (gcloud --format='table[no-heading](name,zone)' --project=$project container clusters --region=$region list | \
                fzf --no-multi --prompt="Select cluster for $name:" --query=$cluster_id | cut -f1 -d' ')
        end

        if test -n "$cluster"
            echo "Using cluster '$cluster' for $name"
            gcloud --project=$project container clusters --region=$region get-credentials $cluster
        end
    end
end
