function k8s-merge-config
    set -l ktemp (mktemp)
    set -l _kubeconfig $KUBECONFIG
    
    set -gx KUBECONFIG $KUBECONFIG:$argv[1]

    kubectl config view --merge --flatten > $ktemp
    cp $ktemp $_kubeconfig

    set -gx KUBECONFIG $_kubeconfig
end
