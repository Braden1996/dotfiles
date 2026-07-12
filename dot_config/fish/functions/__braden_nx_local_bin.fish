function __braden_nx_local_bin --argument-names workspace_root
    test -n "$workspace_root"; or return 1

    set -l nx_bin "$workspace_root/node_modules/.bin/nx"
    test -x "$nx_bin"; or return 1
    echo "$nx_bin"
end
