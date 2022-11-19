# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && . "$HOME/.fig/shell/zshrc.pre.zsh"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
  print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
  command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
  command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
    print -P "%F{33} %F{34}Installation successful.%f%b" || \
    print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
  zdharma-continuum/zinit-annex-as-monitor \
  zdharma-continuum/zinit-annex-bin-gem-node \
  zdharma-continuum/zinit-annex-patch-dl \
  zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# Should Starship add a new line before the prompt?
STARSHIP_PROMPT_NEED_NEWLINE=false

# START - https://github.com/zdharma-continuum/zinit
zinit ice as"command" from"gh-r" \
  atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
  atpull"%atclone" src"init.zsh"
zinit light starship/starship
# END - https://github.com/zdharma-continuum/zinit

# Loading tmux first, to prevent jumps when tmux is loaded after .zshrc
# It will only be loaded on first start
zinit lucid for OMZP::tmux

# START - https://zdharma-continuum.github.io/zinit/wiki/Example-Minimal-Setup/
zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start; ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=\"fg=10\"" \
    zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions
# END - https://zdharma-continuum.github.io/zinit/wiki/Example-Minimal-Setup/


# START - https://github.com/zdharma-continuum/history-search-multi-word
zinit wait="1" lucid light-mode for \
  zdharma-continuum/history-search-multi-word
# END - https://github.com/zdharma-continuum/history-search-multi-word

# #=== OH-MY-ZSH & PREZTO PLUGINS =======================
# https://github.com/ohmyzsh/ohmyzsh/tree/master/lib
zi snippet OMZL::clipboard.zsh
zi snippet OMZL::compfix.zsh
zi snippet OMZL::completion.zsh
zi snippet OMZL::git.zsh
zi snippet OMZL::key-bindings.zsh

# Azure requires register-python-argcomplete
PATH=$PATH:/Users/braden/Library/Python/3.8/bin
[[ -f "/Users/braden/Library/Python/3.8/bin/register-python-argcomplete" ]] && zi snippet https://github.com/ohmyzsh/ohmyzsh/blob/64debaf004b5ec80d9fc849175d3efa7168def44/plugins/azure/azure.plugin.zsh

# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins
zi snippet OMZP::brew
zi snippet OMZP::colored-man-pages
zi snippet OMZP::git
zi snippet OMZP::golang
zi snippet OMZP::npm
zi snippet OMZP::nvm
zi snippet OMZP::pip
zi snippet OMZP::react-native
zi snippet OMZP::terraform
zi snippet OMZP::yarn

# https://github.com/sorin-ionescu/prezto/tree/master/modules
zi snippet PZT::modules/environment
zi snippet PZT::modules/history
zi snippet PZT::modules/rsync

zinit light "MichaelAquilina/zsh-you-should-use"

#=== GITHUB BINARIES ==================================
# diff-s-fancy
zinit ice \
  depth=1 \
  lucid \
  wait'0c' \
  as'program' \
  pick'bin/git-dsf'
zinit light zdharma-continuum/zsh-diff-so-fancy

# fzf: binary
zinit ice \
  lucid \
  wait'0b' \
  from"gh-r" \
  as"program" \
  atload"source ~/.fzf.settings"
zinit light junegunn/fzf

zinit light lukechilds/zsh-nvm

# fzf: completions and key bindings
zinit ice \
  lucid \
  wait'0c' \
  multisrc"shell/{completion,key-bindings}.zsh" \
  id-as"junegunn/fzf_completions" \
  pick"/dev/null"
zinit light junegunn/fzf

# Better tab complete
zinit ice \
  wait'2' \
  lucid \
  atload"
zstyle ':completion:*:*:aws' fzf-search-display true
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --icons --color=always $realpath'
  "
zinit light Aloxaf/fzf-tab

### Zoxide "z" jump
zinit ice wait"1" as"command" from"gh-r" lucid \
  mv"zoxide*/zoxide -> zoxide" \
  atclone"./zoxide init zsh --cmd j > init.zsh" \
  atpull"%atclone" src"init.zsh" nocompile'!'

zinit light ajeetdsouza/zoxide

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && . "$HOME/.fig/shell/zshrc.post.zsh"
