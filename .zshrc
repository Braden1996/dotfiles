# nvim as default edtior
export VISUAL="nvim"
export EDITOR="nvim"

# Krypton
export GPG_TTY=$(tty)

# Handy aliases to edit common files
alias zshx="${EDITOR} ~/.zshrc"
alias nvimx="${EDITOR} ~/.config/nvim/init.vim"
alias gitx="${EDITOR} ~/.gitconfig"
alias hyperx="${EDITOR} ~/.hyper.js"

alias oldls="ls"
alias ls="exa --group-directories-first --icons"

set -o emacs

# Heavy inspiration from:
# https://blog.callstack.io/supercharge-your-terminal-with-zsh-8b369d689770
source <(antibody init)

# Cache completions for faster start up
autoload -Uz compinit
typeset -i updated_at=$(date +'%j' -r ~/.zcompdump 2>/dev/null || stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)
if [ $(date +'%j') != $updated_at ]; then
  compinit -i
else
  compinit -C -i
fi
zmodload -i zsh/complist

antibody bundle < ~/.zsh_plugins.txt
eval "$(starship init zsh)"

# Save history to disk
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE

# Configure how history is saved
setopt histignorespace
export HISTCONTROL=ignorespace
setopt hist_ignore_all_dups # remove older duplicate entries from history
setopt hist_reduce_blanks # remove superfluous blanks from history items
setopt inc_append_history # save history entries as soon as they are entered
setopt share_history # share history between different instances of the shell

setopt auto_cd # cd by typing directory name if it's not a command
setopt correct_all # autocorrect commands
setopt auto_list # automatically list choices on ambiguous completion
setopt auto_menu # automatically use menu completion
setopt always_to_end # move cursor to end if word had one match
zstyle ':completion:*' menu select # select completions with arrow keys
zstyle ':completion:*' group-name '' # group results by category
zstyle ':completion:::::' completer _expand _complete _ignored _approximate # enable approximate matches for completion

bindkey '^[[3~' delete-char
bindkey '^[3;5~' delete-char

# For zsh-users/zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# Configure PyEnv
if command -v pyenv 1>/dev/null 2>&1; then
 eval "$(pyenv init -)"
fi

# Add git key
eval `ssh-agent -s` > /dev/null

[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
eval "$(rbenv init -)"

export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Added by Krypton
export GPG_TTY=$(tty)

# Ruby Env
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Added for Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
