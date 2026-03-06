# =============================================================================
# Completion System
# =============================================================================
# Note: compinit is handled by zephyr's completion plugin

# Ensure cache directory exists
[[ -d ~/.cache/zsh/completions ]] || mkdir -p ~/.cache/zsh/completions

# Completion styling
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.cache/zsh/completions
zstyle ':plugin:ez-compinit' 'compstyle' 'ohmy'

# FZF-tab preview for cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -Gax --icons=always --group-directories-first --git'

# Directory bookmarks (usage: cd ~dl, cd ~cfg)
hash -d dl=~/Downloads
hash -d cfg=~/.config
