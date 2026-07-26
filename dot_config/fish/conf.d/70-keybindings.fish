# =============================================================================
# Key Bindings
# =============================================================================

function __braden_tab_or_yazi
    if test -z (string trim -- (commandline)); and command -q yazi
        yazi_choose
    else
        commandline -f complete
    end
end

function __braden_up_or_history
    if commandline -P
        commandline -f up-line
    else
        __braden_fzf_history
    end
end

function __braden_down_or_history
    if commandline -P
        commandline -f down-line
    else
        __braden_fzf_history
    end
end

function __braden_select_with_motion --argument-names motion
    # Reusing begin-selection resets the anchor, so only start it once.
    set -l selection (commandline -s)
    if test (count $selection) -eq 0
        commandline -f begin-selection
    end

    commandline -f $motion repaint
end

function __braden_move_or_collapse_selection --argument-names edge motion
    set -l selection_start (commandline -B)
    set -l selection_end (commandline -E)

    if test "$selection_start" != "$selection_end"
        switch $edge
            case start
                commandline -C $selection_start
            case end
                commandline -C $selection_end
        end

        commandline -f end-selection repaint
        return
    end

    commandline -f $motion repaint
end

function __braden_up_or_history_or_collapse_selection
    set -l selection_start (commandline -B)
    set -l selection_end (commandline -E)

    if test "$selection_start" != "$selection_end"
        __braden_move_or_collapse_selection start up-line
    else
        __braden_up_or_history
    end
end

function __braden_down_or_history_or_collapse_selection
    set -l selection_start (commandline -B)
    set -l selection_end (commandline -E)

    if test "$selection_start" != "$selection_end"
        __braden_move_or_collapse_selection end down-line
    else
        __braden_down_or_history
    end
end

# Bind a key only when its handler actually resolves. An autoloaded function
# whose file has not been applied yet turns every press of that key into an
# error -- and for Enter that makes the shell unusable until the file lands.
# Leaving the key at its Fish default degrades far better than breaking it.
function __braden_bind_if_available
    set -l key $argv[1]
    set -l handler_command $argv[2..-1]
    set -l handler (string split ' ' -- "$handler_command")[1]
    if functions -q $handler; or type -q $handler
        bind $key $handler_command
    end
end

if status is-interactive; and isatty stdin; and isatty stdout
    __braden_bind_if_available \r __braden_magic_enter
    __braden_bind_if_available \e\e __braden_toggle_sudo
    __braden_bind_if_available \t __braden_tab_or_yazi
    if command -q yazi
        __braden_bind_if_available \cy yazi_choose
    end
    __braden_bind_if_available super-c fish_clipboard_copy
    __braden_bind_if_available left '__braden_move_or_collapse_selection start backward-char'
    __braden_bind_if_available right '__braden_move_or_collapse_selection end forward-char'
    __braden_bind_if_available home '__braden_move_or_collapse_selection start beginning-of-line'
    __braden_bind_if_available end '__braden_move_or_collapse_selection end end-of-line'
    __braden_bind_if_available alt-left '__braden_move_or_collapse_selection start prevd-or-backward-word'
    __braden_bind_if_available alt-right '__braden_move_or_collapse_selection end nextd-or-forward-word'
    __braden_bind_if_available ctrl-a '__braden_move_or_collapse_selection start beginning-of-line'
    __braden_bind_if_available ctrl-e '__braden_move_or_collapse_selection end end-of-line'
    __braden_bind_if_available up __braden_up_or_history_or_collapse_selection
    __braden_bind_if_available down __braden_down_or_history_or_collapse_selection
    __braden_bind_if_available \e\[A __braden_up_or_history_or_collapse_selection
    __braden_bind_if_available \e\[B __braden_down_or_history_or_collapse_selection
    __braden_bind_if_available shift-left '__braden_select_with_motion backward-char'
    __braden_bind_if_available shift-right '__braden_select_with_motion forward-char'
    __braden_bind_if_available shift-up '__braden_select_with_motion up-line'
    __braden_bind_if_available shift-down '__braden_select_with_motion down-line'
    __braden_bind_if_available shift-home '__braden_select_with_motion beginning-of-line'
    __braden_bind_if_available shift-end '__braden_select_with_motion end-of-line'
    __braden_bind_if_available alt-shift-left '__braden_select_with_motion backward-word'
    __braden_bind_if_available alt-shift-right '__braden_select_with_motion forward-word'
end
