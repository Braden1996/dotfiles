function __braden_nx_find_workspace_root --argument-names start_dir
    test -n "$start_dir"; or return 1

    set -l dir (path resolve "$start_dir" 2>/dev/null)
    or set dir "$start_dir"

    while true
        if __braden_nx_is_workspace_root "$dir"
            echo "$dir"
            return 0
        end

        test "$dir" = /; and return 1
        set dir (path dirname "$dir")
    end
end
