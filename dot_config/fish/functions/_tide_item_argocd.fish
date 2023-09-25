function _tide_item_argocd --description 'Show Argo CD context'
    set context (argocd context | string match -gr '\*\s*(\S*)' $l)

    _tide_print_item argocd $tide_argocd_icon' ' $context
end

