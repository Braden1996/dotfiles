# =============================================================================
# Tool Configurations
# =============================================================================

# Detect Homebrew prefix (Apple Silicon vs Intel)
: ${HOMEBREW_PREFIX:=/opt/homebrew}
[[ -d "$HOMEBREW_PREFIX" ]] || HOMEBREW_PREFIX=/usr/local

# -----------------------------------------------------------------------------
# Cached init helper
# -----------------------------------------------------------------------------
# Caches "$cmd init zsh" output, regenerating only when the binary changes.
_cached_init() {
  local cmd=$1 cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  local cache_file="$cache_dir/${cmd}-init.zsh"
  local bin_path="${commands[$cmd]}"

  [[ -z "$bin_path" ]] && return 1
  [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

  if [[ ! -f "$cache_file" || "$bin_path" -nt "$cache_file" ]]; then
    "$cmd" init zsh > "$cache_file" 2>/dev/null
  fi
  source "$cache_file"
}

# -----------------------------------------------------------------------------
# Starship (cached init instead of zephyr prompt bootstrap)
# -----------------------------------------------------------------------------
if (( ${__BRADEN_ZSH_HAS_TTY:-1} )); then
  _cached_init starship
fi

# -----------------------------------------------------------------------------
# Zoxide (cached init instead of subprocess every shell)
# -----------------------------------------------------------------------------
_cached_init zoxide

# -----------------------------------------------------------------------------
# FZF
# -----------------------------------------------------------------------------
export FZF_DEFAULT_OPTS="
  --height=40%
  --layout=reverse
  --border=rounded
  --bind='left:toggle-preview,right:accept'
  --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796
  --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6
  --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796
"

export FZF_CTRL_R_OPTS="
  --preview 'echo {} | sed \"s/^[[:space:]]*[0-9]*[[:space:]]*//\" | bat --color=always --language=zsh --style=plain --theme=\"Catppuccin Macchiato\"'
  --preview-window=right:60%:wrap:border-left
"

# -----------------------------------------------------------------------------
# Mise
# -----------------------------------------------------------------------------
if [[ -x "$HOMEBREW_PREFIX/bin/mise" ]]; then
  eval "$("$HOMEBREW_PREFIX/bin/mise" activate zsh)"
elif command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# -----------------------------------------------------------------------------
# Android & Java (only export if installed)
# -----------------------------------------------------------------------------
[[ -d /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home ]] && \
  export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

[[ -d $HOME/Library/Android/sdk ]] && \
  export ANDROID_HOME=$HOME/Library/Android/sdk

# -----------------------------------------------------------------------------
# GPG (no subshell - uses built-in $TTY)
# -----------------------------------------------------------------------------
export GPG_TTY=$TTY
