function __braden_nx_is_workspace_root --argument-names dir
    test -n "$dir"; or return 1
    test -f "$dir/nx.json"; and return 0
    test -x "$dir/node_modules/.bin/nx"
end
