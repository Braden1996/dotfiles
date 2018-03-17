# nvim as default edtior
export VISUAL="nvim"
export EDITOR="nvim"

# Handy aliases to edit common files
alias zshx="${EDITOR} ~/.zshrc"
alias nvimx="${EDITOR} ~/.config/nvim/init.vim"
alias gitx="${EDITOR} ~/.gitconfig"
alias hyperx="${EDITOR} ~/.hyper.js"

source /usr/local/share/antigen/antigen.zsh

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

# Add git key
ssh-add ~/.ssh/gitkey &> /dev/null

[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
