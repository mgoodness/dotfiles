function kclean
    set -l current_context (kubectl config current-context)
    set -l ktemp (mktemp)

    kubectl config-cleanup --raw >$ktemp
    mv $KUBECONFIG $KUBECONFIG.old
    mv $ktemp $KUBECONFIG

    kubectl config use-context $current_context
end
