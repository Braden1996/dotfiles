function __braden_nx_workspace_root
    set -l workspace_root (__braden_nx_find_workspace_root "$PWD")
    if test -n "$workspace_root"
        echo "$workspace_root"
        return 0
    end

    if set -q BRADEN_NX_DEFAULT_WORKSPACE
        set -l default_workspace (path resolve "$BRADEN_NX_DEFAULT_WORKSPACE" 2>/dev/null)
        or set default_workspace "$BRADEN_NX_DEFAULT_WORKSPACE"

        if __braden_nx_is_workspace_root "$default_workspace"
            echo "$default_workspace"
            return 0
        end
    end

    return 1
end
