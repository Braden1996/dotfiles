# Handy aliases to edit common files
alias zshx="${EDITOR} ~/.zshrc"
alias gitx="${EDITOR} ~/.gitconfig"

if [ -f ~/.bradenssecrets.sh ]; then
  source ~/.bradenssecrets.sh
fi

ANTIGEN_PATH=/opt/homebrew/share/antigen/antigen.zsh
if [ ! -f "$ANTIGEN_PATH" ]; then
    echo "Warning: antigen not found in path."
else
  source $ANTIGEN_PATH

  # # Load bundles from the default repo (oh-my-zsh)
  # antigen use oh-my-zsh
  # antigen bundle git
  # antigen bundle heroku
  # antigen bundle pip
  # antigen bundle lein
  # antigen bundle command-not-found
  # antigen bundle autojump
  # antigen bundle brew
  # antigen bundle common-aliases
  # antigen bundle compleat
  # antigen bundle git-extras
  # antigen bundle git-flow
  # antigen bundle npm
  # antigen bundle osx
  # antigen bundle web-search
  # antigen bundle z

  # # Load bundles from external repos
  # antigen bundle zsh-users/zsh-autosuggestions
  # antigen bundle zsh-users/zsh-completions
  # antigen bundle zsh-users/zsh-history-substring-search ./zsh-history-substring-search.zsh

  # # NVM bundle
  # export NVM_LAZY_LOAD=true
  # antigen bundle lukechilds/zsh-nvm
  # antigen bundle Sparragus/zsh-auto-nvm-use

  # # zsh-users/zsh-syntax-highlighting needs to be last bundle
  # antigen bundle zsh-users/zsh-syntax-highlighting

  antigen apply
fi

mkdir -p ~/.config/zsh/completions

# Neovim
if ! type "nvim" > /dev/null; then
  echo "Warning: neovim is not installed."
  echo "Try: brew install nvim"
else
  export VISUAL="nvim"
  export EDITOR="nvim"
  alias nvimx="${EDITOR} ~/.config/nvim/init.vim"
fi

# Switch between JDK versions
# See: https://github.com/AdoptOpenJDK/homebrew-openjdk
jdk() {
  version=$1
  export JAVA_HOME=$(/usr/libexec/java_home -v"$version");
  java -version
}

# Android SDK
ANDROID_HOME=$HOME/Library/Android/sdk
if [ ! -d "$ANDROID_HOME" ]; then
    echo "Warning: android SDK not found in path."
else
  export PATH=$PATH:$ANDROID_HOME/emulator
  export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
  export PATH=$PATH:$ANDROID_HOME/platform-tools
fi


# Exa
if ! type "exa" > /dev/null; then
  echo "Warning: exa is not installed."
  echo "Try: brew install exa"
else
  alias oldls="ls"
  alias ls="exa --group-directories-first --icons"
fi


# Starship
if ! type "starship" > /dev/null; then
  echo "Warning: starship is not installed."
  echo "Try: brew install starship"
else
  eval "$(starship init zsh)"
fi


# Fnm
if ! type "fnm" > /dev/null; then
  echo "Warning: fnm is not installed."
  echo "Try: brew install fnm"
else
  touch ~/.config/zsh/completions/_fnm
  fnm completions --shell=zsh > ~/.config/zsh/completions/_fnm
  eval "$(fnm env)"
fi

# Rbenv
# TODO: disabled as rbenv + M1 ARM + pod install doesn't seem to work.
# https://stackoverflow.com/questions/64901180/running-cocoapods-on-apple-silicon-m1/65334677#65334677
# if ! type "rbenv" > /dev/null; then
#   echo "Warning: rbenv is not installed."
#   echo "Try: brew install rbenv"
# else
#   export PATH="$HOME/.rbenv/bin:$PATH"
#   eval "$(rbenv init -)"
# fi


# Pyenv
if ! command -v pyenv 1>/dev/null 2>&1; then
  echo "Warning: pyenv is not installed."
  echo "Try: brew install pyenv"
else
  eval "$(pyenv init -)"
fi


# Ranger
if ! type "ranger" > /dev/null; then
  echo "Warning: ranger is not installed."
  echo "Try: brew install ranger"
fi


# Autojump
if [ ! -f /opt/homebrew/etc/profile.d/autojump.sh ]; then
  echo "Warning: autojump is not installed."
  echo "Try: brew install autojump"
else
  . /opt/homebrew/etc/profile.d/autojump.sh
fi
