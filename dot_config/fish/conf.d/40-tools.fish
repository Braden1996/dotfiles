# =============================================================================
# Tool Configuration
# =============================================================================

set -gx FZF_DEFAULT_OPTS (string join " " -- \
    "--height=40%" \
    "--layout=reverse" \
    "--border=rounded" \
    "--bind='left:toggle-preview,right:accept'" \
    "--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796" \
    "--color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6" \
    "--color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796")

set -gx FZF_CTRL_R_OPTS (string join " " -- \
    "--preview 'echo {} | sed \"s/^[[:space:]]*[0-9]*[[:space:]]*//\" | bat --color=always --language=zsh --style=plain --theme=\"Catppuccin Macchiato\"'" \
    "--preview-window=right:60%:wrap:border-left")

if status is-interactive
    if command -q zoxide
        zoxide init fish | source
    end

    if command -q fzf
        fzf --fish | source
    end

    if command -q starship
        starship init fish | source
    end
end
