function nx
    set -l workspace_root (__braden_nx_workspace_root)

    if test -n "$workspace_root"
        set -l nx_bin (__braden_nx_local_bin "$workspace_root")
        if test -n "$nx_bin"
            if command -q mise
                mise exec -C "$workspace_root" -- "$nx_bin" $argv
            else
                env PATH="$PATH" HOME="$HOME" bash -c '
                    cd "$1" || exit 1
                    shift
                    "$@"
                ' bash "$workspace_root" "$nx_bin" $argv
            end
            return $status
        end
    end

    set -l global_nx_bin (__braden_nx_global_bin)
    if test -n "$global_nx_bin"
        "$global_nx_bin" $argv
        return $status
    end

    if test -n "$workspace_root"
        echo "nx is not available at $workspace_root/node_modules/.bin/nx, and $HOME/.bun/bin/nx was not found." >&2
    else
        echo "No Nx workspace found from $PWD, and $HOME/.bun/bin/nx was not found. Set BRADEN_NX_DEFAULT_WORKSPACE to enable nx outside a repo." >&2
    end

    return 1
end
