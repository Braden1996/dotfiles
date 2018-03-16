source /usr/local/share/antigen/antigen.zsh

# Swap out regular vim with neovim
alias vim="nvim"
alias vi="nvim"
alias oldvim="vim"
alias vimdiff='nvim -d'

# Handy aliases to edit common files
alias zshx="vim ~/.zshrc"
alias vimx="vim ~/.config/nvim/init.vim"
alias oldvimx="vim ~/.vimrc"
alias hyperx="vim ~/.hyper.js"
alias gitx="vim ~/.gitconfig"

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
# antigen bundle heroku
antigen bundle node
antigen bundle npm
antigen bundle pip
# antigen bundle lein
antigen bundle safe-paste
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-history-substring-search

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
antigen theme https://github.com/denysdovhan/spaceship-prompt spaceship

# Tell Antigen that you're done.
antigen apply

# For zsh-users/zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

# vim as default edtior
export VISUAL="nvim"
export EDITOR="nvim"

# Add git key
ssh-add ~/.ssh/gitkey &> /dev/null

[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
