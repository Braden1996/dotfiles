function yazi_cd
    command -q yazi; or return 127

    set -l tmpfile (mktemp); or return 1
    yazi --chooser-file="$tmpfile" >/dev/tty

    if test -s "$tmpfile"
        set -l selection (cat "$tmpfile")
        if test -d "$selection"
            cd "$selection"
        end
    end

    rm -f "$tmpfile"
    commandline -f repaint
end
