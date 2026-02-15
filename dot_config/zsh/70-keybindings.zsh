# =============================================================================
# Key Bindings
# =============================================================================

# Emacs key bindings (default, but explicit for safety)
bindkey -e

# FZF history search on arrow keys (only if widget exists)
if (( $+widgets[fzf-history-widget] )); then
  bindkey '^[[A' fzf-history-widget  # Up arrow
  bindkey '^[[B' fzf-history-widget  # Down arrow
fi

# Yazi file picker
bindkey '^y' yazi_choose  # Ctrl+y triggers yazi-based "completion"

# Clipboard support for zsh-shift-select
# ZLE selections are separate from terminal selections, so we need a custom widget
shift-select-copy() {
  if (( REGION_ACTIVE )); then
    zle copy-region-as-kill
    print -n "$CUTBUFFER" | pbcopy
    zle deactivate-region
    zle -K main
  fi
}
zle -N shift-select-copy
bindkey -M shift-select '^[[99;9u' shift-select-copy  # Ghostty Cmd+C sequence

# Debug: test if Ghostty sequence arrives at all (bind in main keymap too)
debug-ghostty-seq() {
  zle -M "DEBUG: Received Cmd+C sequence! REGION_ACTIVE=$REGION_ACTIVE"
}
zle -N debug-ghostty-seq
bindkey -M emacs '^[[99;9u' debug-ghostty-seq
