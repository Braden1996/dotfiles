# Setup Starship prompt
STARSHIP_PROMPT_NEED_NEWLINE=false
zstyle ':zephyr:plugin:prompt' theme 'starship'

# Setup antidote
source "$ANTIDOTE_HOME/antidote.zsh"
antidote load

# Setup arrow keys for history search
MAGIC_ENTER_GIT_COMMAND="git status -u ."
MAGIC_ENTER_OTHER_COMMAND="eza -Gax --icons=always --group-directories-first --git"

# Setup Python
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Setup Maestro
export PATH=$PATH:$HOME/.maestro/bin

# Setup Android Java
export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
export ANDROID_HOME=$HOME/Library/Android/sdk

# Setup rbenv
eval "$(/opt/homebrew/bin/rbenv init - zsh)"

# Warpify ZSH
printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh" }}\x9c'
