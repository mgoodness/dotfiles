function k8s-namespace
    set -l namespace $(__k8s_get_namespace $argv)

    if test -n "$namespace"
        kubectl config set-context --current --namespace=$namespace
    end
end

function __k8s_get_namespace
    if test -n "$argv"
        set -f fzf_query "--query=$argv"
    end

    kubectl get namespaces -o name 2>/dev/null \
        | cut -d/ -f2 \
        | fzf --no-multi $fzf_query
end
