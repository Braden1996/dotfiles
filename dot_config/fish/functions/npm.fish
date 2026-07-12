function npm
    if test (count $argv) -eq 1; and contains -- $argv[1] -v --version
        command npm $argv
        return $status
    end
    __braden_safe_chain_exec npm $argv
end
