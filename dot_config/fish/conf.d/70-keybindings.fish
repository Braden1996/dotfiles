# =============================================================================
# Key Bindings
# =============================================================================

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

if status is-interactive
    bind \r __braden_magic_enter
    bind \e\e __braden_toggle_sudo
    bind \cy yazi_choose
    bind up __braden_up_or_history
    bind down __braden_down_or_history
    bind \e\[A __braden_up_or_history
    bind \e\[B __braden_down_or_history
end
