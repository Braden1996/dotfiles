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

function __braden_cached_init --argument-names cache_name command_name
    set -l cmd_args $argv[3..-1]
    set -l bin_path (type -P $command_name 2>/dev/null)
    test -n "$bin_path"; or return 1

    set -l cache_root "$HOME/.cache"
    set -q XDG_CACHE_HOME; and set cache_root "$XDG_CACHE_HOME"
    set -l cache_dir "$cache_root/fish"
    set -l cache_file "$cache_dir/$cache_name.fish"

    if not test -d "$cache_dir"
        mkdir -p "$cache_dir"
    end

    if not test -s "$cache_file"; or test "$bin_path" -nt "$cache_file"
        set -l temp_file "$cache_file.$fish_pid.tmp"

        if command $command_name $cmd_args >"$temp_file"; and test -s "$temp_file"
            command mv -f "$temp_file" "$cache_file" 2>/dev/null
            or rm -f "$temp_file"
        else
            rm -f "$temp_file"
            test -s "$cache_file"; or return 1
        end
    end

    source "$cache_file"
end

if status is-interactive; and isatty stdin; and isatty stdout
    if command -q zoxide
        __braden_cached_init zoxide-init zoxide init fish
    end

    if command -q fzf
        __braden_cached_init fzf-init fzf --fish
    end

    if command -q starship
        __braden_cached_init starship-init starship init fish --print-full-init
    end
end
