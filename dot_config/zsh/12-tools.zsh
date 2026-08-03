# =============================================================================
# Tool integrations (loaded before UI plugins so widgets are wrapped once)
# =============================================================================

# Detect Homebrew prefix (Apple Silicon vs Intel)
: ${HOMEBREW_PREFIX:=/opt/homebrew}
[[ -d "$HOMEBREW_PREFIX" ]] || HOMEBREW_PREFIX=/usr/local

# -----------------------------------------------------------------------------
# Cached init helper
# -----------------------------------------------------------------------------
# Cache generated shell integration, regenerating only when the binary changes.
_cached_init() {
  local cache_name=$1 command_name=$2
  shift 2

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  local cache_file="$cache_dir/${cache_name}-init.zsh"
  local bin_path="${commands[$command_name]}"
  local tmpfile

  [[ -z "$bin_path" ]] && return 1
  [[ -d "$cache_dir" ]] || mkdir -p "$cache_dir"

  if [[ ! -s "$cache_file" || "$bin_path" -nt "$cache_file" ]]; then
    tmpfile=$(mktemp "${cache_file}.XXXXXXXX") || return 1
    if "$bin_path" "$@" >| "$tmpfile" 2>/dev/null && [[ -s "$tmpfile" ]]; then
      mv -f "$tmpfile" "$cache_file"
    else
      rm -f "$tmpfile"
      [[ -s "$cache_file" ]] || return 1
    fi
  fi
  source "$cache_file"
}

# -----------------------------------------------------------------------------
# FZF (native shell integration)
# -----------------------------------------------------------------------------
if (( ${__BRADEN_ZSH_HAS_TTY:-1} )); then
  _cached_init fzf fzf --zsh
fi

# -----------------------------------------------------------------------------
# Zoxide (cached init instead of subprocess every shell)
# -----------------------------------------------------------------------------
_cached_init zoxide zoxide init zsh

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
# Fast path: shims in PATH handle runtime selection without a shell hook.
# Opt back into full activation hooks by exporting BRADEN_ENABLE_MISE_HOOKS=1.
if [[ "${BRADEN_ENABLE_MISE_HOOKS:-0}" == "1" ]]; then
  if [[ -x "$HOMEBREW_PREFIX/bin/mise" ]]; then
    eval "$("$HOMEBREW_PREFIX/bin/mise" activate zsh)"
  elif command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
  fi
fi

# Direnv (cached hook; reloads only when the binary changes)
if (( $+commands[direnv] )); then
  _cached_init direnv direnv hook zsh
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

unfunction _cached_init
