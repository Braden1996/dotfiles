function fish-check-deps
    set -l required starship fzf mise
    set -l optional eza bat yazi zoxide safe-chain
    set -l missing_required
    set -l missing_optional

    for cmd in $required
        command -q $cmd; or set -a missing_required $cmd
    end
    for cmd in $optional
        command -q $cmd; or set -a missing_optional $cmd
    end

    if test (count $missing_required) -gt 0
        set_color red
        echo "[fish] Missing required: "(string join ", " -- $missing_required)
        set_color yellow
        echo "  brew install "(string join " " -- $missing_required)
    else
        set_color green
        echo "All required dependencies installed"
    end
    set_color normal

    if test (count $missing_optional) -gt 0
        set_color brblack
        echo "[fish] Optional: "(string join ", " -- $missing_optional)
        set_color normal
    end
end
