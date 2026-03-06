# =============================================================================
# Environment & PATH Configuration
# =============================================================================

# Detect Homebrew prefix (Apple Silicon vs Intel).
set -l homebrew_prefix /opt/homebrew
if not test -d $homebrew_prefix
    set homebrew_prefix /usr/local
end

set -gx HOMEBREW_PREFIX $homebrew_prefix
set -gx HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
set -gx HOMEBREW_REPOSITORY $HOMEBREW_PREFIX

# Keep PATH ordering aligned with the existing zsh setup.
fish_add_path -gPm "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin"
fish_add_path -gPm "$HOME/.local/bin"
fish_add_path -gPm "$HOME/.local/share/mise/shims"
fish_add_path -gPm "$HOME/.cargo/bin"
fish_add_path -gPm "$HOME/.bun/bin"
fish_add_path -gPm "$HOME/.antigravity/antigravity/bin"
fish_add_path -gPa "$HOME/Library/Android/sdk/platform-tools"
fish_add_path -gPa "$HOME/.safe-chain/bin"

set -gx INFOPATH "$HOMEBREW_PREFIX/share/info" $INFOPATH
if set -q MANPATH[1]
    set -gx MANPATH "" $MANPATH
end

# Prefer a terminal-provided startup timestamp so Fish startup avoids extra
# subprocesses just to measure prompt latency.

if test -d /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
    set -gx JAVA_HOME /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
end

if test -d "$HOME/Library/Android/sdk"
    set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
end

if status is-interactive
    set -gx GPG_TTY (tty)
end
