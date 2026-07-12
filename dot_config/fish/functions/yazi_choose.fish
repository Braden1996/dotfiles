function yazi_choose
    command -q yazi; or return 127

    set -l chooser (mktemp); or return 1
    set -l cwdfile (mktemp)
    or begin
        rm -f "$chooser"
        return 1
    end

    yazi --chooser-file="$chooser" --cwd-file="$cwdfile" >/dev/tty

    if test -s "$chooser"
        set -l selection (cat "$chooser")
        commandline --insert -- (string escape -- $selection)
    else if test -s "$cwdfile"
        set -l dir (cat "$cwdfile")
        if test -d "$dir"; and test "$dir" != "$PWD"
            cd "$dir"
        end
    end

    rm -f "$chooser" "$cwdfile"
    commandline -f repaint
end
