function __braden_nx_global_bin
    set -l nx_bin "$HOME/.bun/bin/nx"
    test -x "$nx_bin"; or return 1

    echo "$nx_bin"
end
