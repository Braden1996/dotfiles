if status is-interactive
    if set -q __BRADEN_SHELL_START_REAL
        set -l shell_start_now

        if command -q perl
            set shell_start_now (command perl -MTime::HiRes=time -e 'printf "%.6f\n", time')
        else if command -q python3
            set shell_start_now (command python3 -c 'import time; print(f"{time.time():.6f}")')
        end

        if set -q shell_start_now
            set -gx ZSH_STARTUP_MS (math -s0 "($shell_start_now - $__BRADEN_SHELL_START_REAL) * 1000")
        end

        set -e __BRADEN_SHELL_START_REAL
    end
end
