# =============================================================================
# Plugin Management (Antidote)
# =============================================================================

# Starship prompt configuration (must be before zephyr prompt)
STARSHIP_PROMPT_NEED_NEWLINE=false
zstyle ':zephyr:plugin:prompt' theme 'starship'
zstyle ':zephyr:plugin:prompt' use-cache yes
zstyle ':zephyr:plugin:prompt' immediate yes

# Completion configuration
zstyle ':zephyr:plugin:completion' use-cache yes
zstyle ':zephyr:plugin:completion' immediate yes

# Magic enter configuration (must be before magic-enter plugin loads)
MAGIC_ENTER_GIT_COMMAND="git status -u ."
MAGIC_ENTER_OTHER_COMMAND="eza -Gax --icons=always --group-directories-first --git"

# Autosuggestions performance settings
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# Set ANTIDOTE_HOME default if not set (Homebrew, then git clone fallback)
if [[ -z "$ANTIDOTE_HOME" ]]; then
  ANTIDOTE_HOME="${XDG_CACHE_HOME:-$HOME/Library/Caches}/antidote"
fi

# Load antidote (with error handling)
local antidote_script=""
if [[ -f "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh" ]]; then
  antidote_script="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh"
elif [[ -f "$ANTIDOTE_HOME/antidote.zsh" ]]; then
  antidote_script="$ANTIDOTE_HOME/antidote.zsh"
fi

if [[ -n "$antidote_script" ]]; then
  source "$antidote_script"
else
  print -P "%F{red}[zshrc] antidote not found (cache: $ANTIDOTE_HOME)%f" >&2
  print -P "%F{yellow}  Install: brew install antidote%f" >&2
  return 1
fi
unset antidote_script

# Static plugin loading (faster than dynamic)
# Regenerate with: antidote bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.zsh
if [[ ! -f ~/.zsh_plugins.zsh ]] || [[ ~/.zsh_plugins.txt -nt ~/.zsh_plugins.zsh ]]; then
  # Atomic write to prevent race conditions
  local tmpfile="${TMPDIR:-/tmp}/zsh_plugins.$$.zsh"
  antidote bundle < ~/.zsh_plugins.txt > "$tmpfile" && mv "$tmpfile" ~/.zsh_plugins.zsh
  # Compile for faster loading
  zcompile ~/.zsh_plugins.zsh
fi
source ~/.zsh_plugins.zsh
