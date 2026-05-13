function akuity-manifests
    for file in $(fd -e yml '\w{3}-\w{3}-\d' $argv)
        set -l ballpark (yq .metadata.labels.ballpark $file)
        set -l cluster_id (yq .metadata.labels.cluster $file)
        set -l league (yq .metadata.labels.league $file)
        set -l name (yq .metadata.name $file)

        set -l fzf_query "$league $ballpark"
        if test "$league" = mlb
            set fzf_query "mlb-ballpark-prod-$ballpark-cluster$cluster_id"
        end

        set -l context (kubectl config get-contexts -o name 2>/dev/null \
            | fzf --no-multi --prompt="Select context for cluster $name: " --query="$fzf_query")

        if test -n "$context"
            kubectl config use-context $context
            akuity argocd cluster get-agent-manifests --org-id=rlltpuvdhhwujsmv --instance-id=gugm3o8xtx7rw3nh $name | kubectl --context=$context apply -f -
        end
    end

    # for file in $(fd -e yml -E "*pci*" gcp $argv)
    #     set -l cluster_id (yq .metadata.labels.cluster $file)
    #     set -l name (yq .metadata.name $file)
    #     set -l project (yq .metadata.labels.gcp-project $file)
    #     set -l region (yq .metadata.labels.region $file)

    #     set -l context (kubectl config get-contexts -o name 2>/dev/null \
    #         | fzf --no-multi --prompt="Select context for cluster $name: " --query="$project $region $cluster_id")

    #     if test -n "$context"
    #         kubectl config use-context $context
    #         akuity argocd cluster get-agent-manifests --org-id=rlltpuvdhhwujsmv --instance-id=gugm3o8xtx7rw3nh $name | kubectl --context=$context apply -f -
    #     end
    # end
end
