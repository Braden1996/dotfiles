# =============================================================================
# Shell Options
# =============================================================================

# -----------------------------------------------------------------------------
# History Configuration
# -----------------------------------------------------------------------------
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"

setopt extended_history       # Record timestamp
setopt hist_ignore_all_dups   # Remove older duplicates
setopt hist_save_no_dups      # Don't write duplicates
setopt hist_find_no_dups      # Skip duplicates when searching
setopt hist_reduce_blanks     # Trim whitespace
setopt hist_verify            # Show before executing
setopt share_history          # Share across sessions
setopt hist_ignore_space      # Ignore space-prefixed commands

# -----------------------------------------------------------------------------
# Navigation
# -----------------------------------------------------------------------------
setopt auto_cd              # Type directory name to cd
setopt auto_pushd           # cd pushes to directory stack
setopt pushd_ignore_dups    # No duplicates in stack
setopt pushd_silent         # Don't print stack after pushd

# -----------------------------------------------------------------------------
# Completion Behavior
# -----------------------------------------------------------------------------
setopt COMPLETE_IN_WORD     # Complete from cursor position
setopt ALWAYS_TO_END        # Move cursor to end after completion
setopt AUTO_MENU            # Show completion menu on successive tab
setopt glob_dots            # Include dotfiles in globs

# -----------------------------------------------------------------------------
# Miscellaneous
# -----------------------------------------------------------------------------
setopt correct              # Spell correction for commands
setopt interactive_comments # Allow comments in interactive shell
setopt NO_BEEP              # Silence terminal bells
setopt NO_NOMATCH           # Don't error on failed globs
setopt NO_FLOW_CONTROL      # Disable Ctrl+S/Ctrl+Q flow control
