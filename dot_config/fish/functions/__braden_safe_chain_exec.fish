function __braden_safe_chain_exec --argument-names original_cmd
    set -l cmd_args $argv[2..-1]
    set -l resolved_cmd

    if command -q $original_cmd
        set resolved_cmd $original_cmd
    else
        switch $original_cmd
            case yarn pnpm
                command -q corepack; and set resolved_cmd corepack $original_cmd
            case pnpx
                command -q corepack; and set resolved_cmd corepack pnpm dlx
        end
    end

    # Shell scripts and `fish -c` calls must remain deterministic and quiet.
    # Safe-chain is an interactive guardrail for package-manager commands only.
    if not status is-interactive
        if test (count $resolved_cmd) -gt 0
            command $resolved_cmd $cmd_args
        else
            command $original_cmd $cmd_args
        end
        return $status
    end

    if command -q safe-chain; and test (count $resolved_cmd) -gt 0; and test "$resolved_cmd[1]" = "$original_cmd"
        safe-chain $original_cmd $cmd_args
        return $status
    end

    if not command -q safe-chain; and not set -q __BRADEN_SAFE_CHAIN_WARNED
        set -g __BRADEN_SAFE_CHAIN_WARNED 1
        set_color -b yellow black
        printf "Warning:"
        set_color normal
        printf " safe-chain is unavailable; %s will run without it.\n" $original_cmd
    end

    if test (count $resolved_cmd) -gt 0
        command $resolved_cmd $cmd_args
    else
        command $original_cmd $cmd_args
    end
end
