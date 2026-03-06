# =============================================================================
# Key Bindings
# =============================================================================

if status is-interactive
    bind \r __braden_magic_enter
    bind \e\e __braden_toggle_sudo
    bind \cy yazi_choose
    bind up __braden_fzf_history
    bind down __braden_fzf_history
    bind \e\[A __braden_fzf_history
    bind \e\[B __braden_fzf_history
end
