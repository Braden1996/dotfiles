function __braden_fzf_history
    if not command -q fzf
        commandline -f up-line
        return
    end

    set -l history_delim (printf '\t')
    set -l selection (history search --show-time="%s$history_delim" --max=2000 | fzf \
        --scheme=history \
        --no-sort \
        --delimiter="$history_delim" \
        --with-nth=2.. \
        --preview='__braden_fzf_history_preview {1} {2..}' \
        --preview-window=right:60%:wrap:border-left \
        --query=(commandline))

    if test -n "$selection"
        set -l selection_fields (string split -m1 $history_delim -- $selection)
        if test (count $selection_fields) -ge 2
            commandline --replace -- $selection_fields[2]
        else
            commandline --replace -- $selection
        end
    end
    commandline -f repaint
end
