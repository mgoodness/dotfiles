function pi --wraps=pi --description 'pi wrapper: apply directory-scoped default provider/model from mise env vars'
    # Host mise.toml files (Code/{host}/mise.toml) export PI_DEFAULT_PROVIDER and
    # PI_DEFAULT_MODEL so a given host's repos default to a specific provider/model
    # regardless of the machine's global ~/.pi/agent/settings.json profile seed.
    # Only apply to the default run mode, not to subcommands like `pi install`.
    set --local subcommands install remove uninstall update list config auth
    set --local args $argv

    if set --query PI_DEFAULT_PROVIDER
        and set --query PI_DEFAULT_MODEL
        and not contains -- --provider $argv
        and not contains -- --model $argv
        and begin
            test (count $argv) -eq 0
            or not contains -- $argv[1] $subcommands
        end
        set args --provider $PI_DEFAULT_PROVIDER --model $PI_DEFAULT_MODEL $args
    end

    command pi $args
end
