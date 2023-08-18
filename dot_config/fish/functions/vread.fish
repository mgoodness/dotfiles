function vread
    vault read -format=json $argv[1] | jq -c '.data' | pbcopy
end
