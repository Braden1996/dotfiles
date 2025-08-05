# =============================================================================
# ZSH Configuration File
# =============================================================================
#
# Prerequisites (install via Homebrew):
# brew install fzf starship rbenv pyenv eza antidote
#
# This configuration provides:
# - Modern prompt with Starship
# - Package management with Antidote
# - Enhanced history and search functionality
# - Development environment setup (Python, Ruby, Android)
# - Git integration and signing
# - Improved completion and navigation

# =============================================================================
# PROMPT CONFIGURATION
# =============================================================================

# Configure Starship prompt
STARSHIP_PROMPT_NEED_NEWLINE=false
zstyle ':zephyr:plugin:prompt' theme 'starship'

# =============================================================================
# PACKAGE MANAGEMENT
# =============================================================================

# Setup Antidote for plugin management
source "$ANTIDOTE_HOME/antidote.zsh"
antidote load

# =============================================================================
# HISTORY AND SEARCH CONFIGURATION
# =============================================================================

# Enhanced history settings
HISTSIZE=5000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase

# History behavior options
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space

# Arrow key history search with fzf
bindkey '^[[A' fzf-history-widget  # Up arrow
bindkey '^[[B' fzf-history-widget  # Down arrow

# Magic enter configuration for git and file listing
MAGIC_ENTER_GIT_COMMAND="git status -u ."
MAGIC_ENTER_OTHER_COMMAND="eza -Gax --icons=always --group-directories-first --git"

# =============================================================================
# DEVELOPMENT ENVIRONMENT SETUP
# =============================================================================

# Lazy loading functions for heavy tools
# These functions only load the tools when they're actually used

# Lazy load pyenv
pyenv() {
  unset -f pyenv
  if command -v pyenv >/dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
  fi
  pyenv "$@"
}

# Lazy load rbenv
rbenv() {
  unset -f rbenv
  if command -v rbenv >/dev/null; then
    eval "$(/opt/homebrew/bin/rbenv init - zsh)"
  fi
  rbenv "$@"
}

# Lazy load nvm
nvm() {
  unset -f nvm
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    source "$HOME/.nvm/nvm.sh"
  fi
  nvm "$@"
}

# Lazy load node (if nvm is used)
node() {
  unset -f node
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    source "$HOME/.nvm/nvm.sh"
  fi
  node "$@"
}

# Lazy load npm (if nvm is used)
npm() {
  unset -f npm
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    source "$HOME/.nvm/nvm.sh"
  fi
  npm "$@"
}

# Lazy load npx (if nvm is used)
npx() {
  unset -f npx
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    source "$HOME/.nvm/nvm.sh"
  fi
  npx "$@"
}

# Android development setup
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
export ANDROID_HOME=$HOME/Library/Android/sdk

# =============================================================================
# GIT AND SECURITY
# =============================================================================

# Git signing configuration
export GPG_TTY=$(tty)

# =============================================================================
# ALIASES AND SHORTCUTS
# =============================================================================

# Claude AI assistant
alias claude="/Users/braden/.claude/local/claude"

# =============================================================================
# COMPLETION AND NAVIGATION
# =============================================================================

yazi_choose() {
  local tmpfile="$(mktemp)"
  yazi --chooser-file="$tmpfile" >/dev/tty
  if [[ -f "$tmpfile" && -s "$tmpfile" ]]; then
    LBUFFER+=$(<"$tmpfile")
  fi
  rm -f "$tmpfile"
  zle redisplay
}
zle -N yazi_choose
bindkey '^y' yazi_choose  # Ctrl+y triggers yazi-based "completion"

yazi_cd() {
  local tmpfile="$(mktemp)"
  yazi --chooser-file="$tmpfile" >/dev/tty
  local selection=$(<"$tmpfile")
  rm -f "$tmpfile"

  if [[ -d "$selection" ]]; then
    cd "$selection"
    zle reset-prompt
  fi
}
zle -N yazi_cd

smart_tab() {
  if [[ -z "$BUFFER" ]]; then
    zle yazi_cd
  else
    zle expand-or-complete
  fi
}
zle -N smart_tab
bindkey '^I' smart_tab  # ^I is literal Tab

# Ensure emacs key bindings (default, but explicit for safety)
bindkey -e

# Completion styling
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -Gax --icons=always --group-directories-first --git'
zstyle ':plugin:ez-compinit' 'compstyle' 'ohmy'

export FZF_DEFAULT_OPTS="--bind='left:toggle-preview,right:accept'"

# =============================================================================
# EXTERNAL PLUGINS AND TOOLS
# =============================================================================

# Nx completion plugin
[ -s "/Users/braden/.nx-completion/nx-completion.plugin.zsh" ] && source "/Users/braden/.nx-completion/nx-completion.plugin.zsh"

