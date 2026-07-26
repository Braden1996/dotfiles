function __braden_magic_enter
    set -l buffer (string trim -- (commandline))

    if test -n "$buffer"
        commandline -f execute
        return
    end

    if command git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null
        commandline --replace -- "git status -u ."
    else if command -q eza
        commandline --replace -- "eza -Gax --icons=always --group-directories-first --git"
    else
        commandline --replace -- "ls -lh ."
    end
    commandline -f execute
end
