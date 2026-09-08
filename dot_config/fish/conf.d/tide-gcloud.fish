# Tide's own gcloud segment reads ~/.config/gcloud/active_config directly, ignoring CLOUDSDK_ACTIVE_CONFIG_NAME
function __tide_item_gcloud
    set -q CLOUDSDK_CONFIG || set -l CLOUDSDK_CONFIG ~/.config/gcloud
    set -l config $CLOUDSDK_ACTIVE_CONFIG_NAME
    test -n "$config" || set config (cat $CLOUDSDK_CONFIG/active_config 2>/dev/null)
    test -n "$config" || return 1
    path is $CLOUDSDK_CONFIG/configurations/config_$config &&
        string match -qr '^\s*project\s*=\s*(?<project>.*)' <$CLOUDSDK_CONFIG/configurations/config_$config &&
        _tide_print_item gcloud $tide_gcloud_icon' ' $project
end
