# =============================================================================
# Aliases
# =============================================================================

if command -q eza
    alias la='eza -lah --icons --group-directories-first'
    alias ll='eza -lh --icons --group-directories-first'
    alias lt='eza -T --icons --level=2'
end

if command -q git
    # Common Oh-My-Zsh git aliases mirrored for fish.
    alias g='git'
    alias ga='git add'
    alias gaa='git add --all'
    alias gapa='git add --patch'
    alias gau='git add --update'
    alias gav='git add --verbose'
    alias gb='git branch'
    alias gba='git branch --all'
    alias gbd='git branch --delete'
    alias gco='git checkout'
    alias gcb='git checkout -b'
    alias gc='git commit --verbose'
    alias gca='git commit --verbose --all'
    alias gcam='git commit --all --message'
    alias gcl='git clone --recurse-submodules'
    alias gd='git diff'
    alias gdca='git diff --cached'
    alias gf='git fetch'
    alias gl='git pull'
    alias gpr='git pull --rebase'
    alias gp='git push'
    alias gpf='git push --force-with-lease'
    alias grh='git reset'
    alias grhh='git reset --hard'
    alias grs='git restore'
    alias grst='git restore --staged'
    alias gsh='git show'
    alias gsta='git stash push'
    alias gstl='git stash list'
    alias gstp='git stash pop'
    alias gst='git status'
    alias gss='git status --short'
    alias gsb='git status --short --branch'
    alias gsw='git switch'
    alias gswc='git switch --create'
end
