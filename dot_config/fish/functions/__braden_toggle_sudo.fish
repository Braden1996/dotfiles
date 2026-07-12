function __braden_toggle_sudo
    set -l buffer (commandline)
    test -n "$buffer"; or set buffer (history --max=1)

    if string match -qr '^sudo ' -- $buffer
        commandline --replace -- (string replace -r '^sudo ' '' -- $buffer)
    else
        commandline --replace -- "sudo $buffer"
    end
    commandline -f repaint
end
