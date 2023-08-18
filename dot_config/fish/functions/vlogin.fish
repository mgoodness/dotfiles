function vlogin
    set -gx VAULT_ADDR "https://vault-npd.shared.mlbinfra.net"

    if test "$argv[1]" = prod
        set -gx VAULT_ADDR "https://vault.shared.mlbinfra.net"
    end

    vault login -no-print -method=oidc role=admin
end
