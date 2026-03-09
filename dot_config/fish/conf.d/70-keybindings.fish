# =============================================================================
# Key Bindings
# =============================================================================

function __braden_tab_or_yazi
    if test -z (string trim -- (commandline))
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

if status is-interactive
    bind \r __braden_magic_enter
    bind \e\e __braden_toggle_sudo
    bind \t __braden_tab_or_yazi
    bind \cy yazi_choose
    bind super-c fish_clipboard_copy
    bind left '__braden_move_or_collapse_selection start backward-char'
    bind right '__braden_move_or_collapse_selection end forward-char'
    bind home '__braden_move_or_collapse_selection start beginning-of-line'
    bind end '__braden_move_or_collapse_selection end end-of-line'
    bind alt-left '__braden_move_or_collapse_selection start prevd-or-backward-word'
    bind alt-right '__braden_move_or_collapse_selection end nextd-or-forward-word'
    bind ctrl-a '__braden_move_or_collapse_selection start beginning-of-line'
    bind ctrl-e '__braden_move_or_collapse_selection end end-of-line'
    bind up __braden_up_or_history_or_collapse_selection
    bind down __braden_down_or_history_or_collapse_selection
    bind \e\[A __braden_up_or_history_or_collapse_selection
    bind \e\[B __braden_down_or_history_or_collapse_selection
    bind shift-left '__braden_select_with_motion backward-char'
    bind shift-right '__braden_select_with_motion forward-char'
    bind shift-up '__braden_select_with_motion up-line'
    bind shift-down '__braden_select_with_motion down-line'
    bind shift-home '__braden_select_with_motion beginning-of-line'
    bind shift-end '__braden_select_with_motion end-of-line'
    bind alt-shift-left '__braden_select_with_motion backward-word'
    bind alt-shift-right '__braden_select_with_motion forward-word'
end
