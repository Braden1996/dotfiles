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

# Prefer a terminal-provided startup timestamp. Fall back to Fish init timing.
if status is-interactive; and not set -q __BRADEN_SHELL_START_REAL
    if command -q perl
        set -gx __BRADEN_SHELL_START_REAL (command perl -MTime::HiRes=time -e 'printf "%.6f\n", time')
    else if command -q python3
        set -gx __BRADEN_SHELL_START_REAL (command python3 -c 'import time; print(f"{time.time():.6f}")')
    end
end

if test -d /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
    set -gx JAVA_HOME /Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
end

if test -d "$HOME/Library/Android/sdk"
    set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
end

if status is-interactive
    set -gx GPG_TTY (tty)
end
