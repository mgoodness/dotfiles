function docker --description "Docker wrapper to ensure Colima is running"
    if ! pgrep -q colima
        colima start || exit 1
    end

    command docker $argv
end
