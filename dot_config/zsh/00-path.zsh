# =============================================================================
# PATH Configuration
# =============================================================================
# Consolidated PATH modifications - order matters (last added = highest priority)

# Homebrew (should already be in PATH from /etc/zprofile, but ensure it)
[[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin $path)

# Android SDK
[[ -d "$HOME/Library/Android/sdk/platform-tools" ]] && path+=("$HOME/Library/Android/sdk/platform-tools")

# Bun
[[ -d "$HOME/.bun/bin" ]] && path=("$HOME/.bun/bin" $path)

# Antigravity
[[ -d "$HOME/.antigravity/antigravity/bin" ]] && path=("$HOME/.antigravity/antigravity/bin" $path)

# De-duplicate PATH
typeset -U path
