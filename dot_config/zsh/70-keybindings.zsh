# =============================================================================
# Key Bindings
# =============================================================================

# Emacs key bindings (default, but explicit for safety)
bindkey -e

# -----------------------------------------------------------------------------
# Magic enter (replaces OMZ magic-enter plugin)
# -----------------------------------------------------------------------------
# Pressing Enter on an empty line runs a context-aware command
magic-enter() {
  [[ -n "$BUFFER" || "$CONTEXT" != start ]] && return
  if command git rev-parse --is-inside-work-tree &>/dev/null; then
    BUFFER="${MAGIC_ENTER_GIT_COMMAND:-git status -u .}"
  else
    BUFFER="${MAGIC_ENTER_OTHER_COMMAND:-ls -lh .}"
  fi
}
_magic-enter_accept-line() {
  magic-enter
  zle .accept-line
}
zle -N accept-line _magic-enter_accept-line

# -----------------------------------------------------------------------------
# Sudo toggle (replaces OMZ sudo plugin)
# -----------------------------------------------------------------------------
# Press Esc-Esc to toggle sudo prefix
sudo-command-line() {
  [[ -z "$BUFFER" ]] && LBUFFER="$(fc -ln -1)"
  case "$BUFFER" in
    sudo\ *) BUFFER="${BUFFER#sudo }" ;;
    *) LBUFFER="sudo $LBUFFER" ;;
  esac
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line

# FZF history search on arrow keys (only if widget exists)
if (( $+widgets[fzf-history-widget] )); then
  bindkey '^[[A' fzf-history-widget  # Up arrow
  bindkey '^[[B' fzf-history-widget  # Down arrow
fi

# Yazi file picker
bindkey '^y' yazi_choose  # Ctrl+y triggers yazi-based "completion"

# Clipboard support for zsh-shift-select
if bindkey -M shift-select >/dev/null 2>&1; then
  shift-select-copy() {
    if (( REGION_ACTIVE )); then
      zle copy-region-as-kill
      print -n "$CUTBUFFER" | pbcopy
      zle deactivate-region
      zle -K main
    fi
  }
  zle -N shift-select-copy
  bindkey -M shift-select "^[[99;9u" shift-select-copy
fi

# Debug: test if Ghostty sequence arrives at all (bind in main keymap too)
debug-ghostty-seq() {
  zle -M "DEBUG: Received Cmd+C sequence! REGION_ACTIVE=$REGION_ACTIVE"
}
zle -N debug-ghostty-seq
bindkey -M emacs '^[[99;9u' debug-ghostty-seq
