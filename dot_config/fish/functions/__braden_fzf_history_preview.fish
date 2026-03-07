function __braden_fzf_history_preview --argument-names timestamp command
    set -l absolute_time
    if date -r $timestamp '+%Y-%m-%d %H:%M:%S %Z' >/dev/null 2>/dev/null
        set absolute_time (date -r $timestamp '+%Y-%m-%d %H:%M:%S %Z')
    else
        set absolute_time (date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null)
    end

    set -l now (date +%s)
    set -l delta (math "max(0, $now - $timestamp)")
    set -l age

    if test $delta -lt 60
        set age "$delta"s ago
    else if test $delta -lt 3600
        set age (math --scale=0 "$delta / 60")"m ago"
    else if test $delta -lt 86400
        set age (math --scale=0 "$delta / 3600")"h ago"
    else if test $delta -lt 604800
        set age (math --scale=0 "$delta / 86400")"d ago"
    else if test $delta -lt 2592000
        set age (math --scale=0 "$delta / 604800")"w ago"
    else if test $delta -lt 31536000
        set age (math --scale=0 "$delta / 2592000")"mo ago"
    else
        set age (math --scale=0 "$delta / 31536000")"y ago"
    end

    printf 'Ran: %s\nAgo: %s\n\n' "$absolute_time" "$age"

    if command -q bat
        printf '%s\n' "$command" | bat \
            --color=always \
            --language=fish \
            --style=plain \
            --theme='Catppuccin Macchiato'
    else
        printf '%s\n' "$command"
    end
end
