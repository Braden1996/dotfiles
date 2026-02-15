# =============================================================================
# Tool Configurations
# =============================================================================

# Detect Homebrew prefix (Apple Silicon vs Intel)
: ${HOMEBREW_PREFIX:=/opt/homebrew}
[[ -d "$HOMEBREW_PREFIX" ]] || HOMEBREW_PREFIX=/usr/local

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
# NVM (with .nvmrc auto-switching)
# -----------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
_nvm_loaded=0

_nvm_load() {
  (( _nvm_loaded )) && return 0
  unset -f nvm node npm npx yarn pnpm 2>/dev/null

  local nvm_script="$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  if [[ -s "$nvm_script" ]]; then
    \. "$nvm_script"
    [[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]] && \
      \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
    _nvm_loaded=1
    return 0
  else
    print -P "%F{yellow}nvm not found at $nvm_script%f" >&2
    return 1
  fi
}

_nvm_use_if_nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc 2>/dev/null)" || return
  [[ -z "$nvmrc_path" ]] && return

  local nvmrc_node_version
  nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")" 2>/dev/null)

  if [[ "$nvmrc_node_version" == "N/A" ]]; then
    nvm install
  elif [[ "$(nvm current)" != "$nvmrc_node_version" ]]; then
    nvm use
  fi
}

# Lazy loaders for node commands
nvm() { _nvm_load && nvm "$@"; }
node() { _nvm_load && _nvm_use_if_nvmrc; node "$@"; }
npm() { _nvm_load && _nvm_use_if_nvmrc; npm "$@"; }
npx() { _nvm_load && _nvm_use_if_nvmrc; npx "$@"; }
yarn() { _nvm_load && _nvm_use_if_nvmrc; yarn "$@"; }
pnpm() { _nvm_load && _nvm_use_if_nvmrc; pnpm "$@"; }

# Auto-switch node version when changing directories
autoload -U add-zsh-hook
_nvm_chpwd_hook() {
  # Load NVM if entering directory with .nvmrc
  if ! (( _nvm_loaded )) && [[ -f ".nvmrc" ]]; then
    _nvm_load
  fi
  (( _nvm_loaded )) && _nvm_use_if_nvmrc
}
add-zsh-hook chpwd _nvm_chpwd_hook

# -----------------------------------------------------------------------------
# pyenv (lazy loaded)
# -----------------------------------------------------------------------------
pyenv() {
  unset -f pyenv
  if command -v pyenv >/dev/null; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
  fi
  pyenv "$@"
}

# -----------------------------------------------------------------------------
# rbenv (lazy loaded)
# -----------------------------------------------------------------------------
rbenv() {
  unset -f rbenv
  if command -v rbenv >/dev/null; then
    eval "$("$HOMEBREW_PREFIX/bin/rbenv" init - zsh)"
  fi
  rbenv "$@"
}

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
