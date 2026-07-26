# =============================================================================
# Shift-select clipboard integration
# =============================================================================
# Loaded after the plugin bundle creates the shift-select keymap. This widget
# does not modify the command buffer, so it does not need UI-plugin wrapping.

if bindkey -M shift-select >/dev/null 2>&1; then
  shift-select-copy() {
    if (( REGION_ACTIVE )); then
      zle copy-region-as-kill
      if (( ${+commands[pbcopy]} )); then
        print -rn -- "$CUTBUFFER" | pbcopy
      elif (( ${+commands[wl-copy]} )); then
        print -rn -- "$CUTBUFFER" | wl-copy
      elif (( ${+commands[xclip]} )); then
        print -rn -- "$CUTBUFFER" | xclip -selection clipboard
      else
        zle -M "Selection copied to the kill ring (no system clipboard tool found)"
      fi
      zle deactivate-region
      zle -K main
    fi
  }
  zle -N shift-select-copy
  bindkey -M shift-select "^[[99;9u" shift-select-copy
fi
