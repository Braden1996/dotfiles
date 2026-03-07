# =============================================================================
# Prompt State
# =============================================================================

function __braden_find_git_root
    set -l dir $PWD

    while true
        if test -e "$dir/.git"
            echo $dir
            return 0
        end

        if test "$dir" = "/"
            return 1
        end

        set dir (path dirname $dir)
    end
end

function __braden_set_starship_git_dirty
    set -e -g BRADEN_GIT_DIRTY

    set -l git_root (__braden_find_git_root)
    or return

    command git -C "$git_root" diff-index --quiet HEAD -- ^/dev/null
    or begin
        set -gx BRADEN_GIT_DIRTY "*"
        return
    end

    set -l untracked (command git -C "$git_root" ls-files --others --exclude-standard --directory --no-empty-directory | head -n 1)
    if test -n "$untracked"
        set -gx BRADEN_GIT_DIRTY "*"
    end
end

if status is-interactive
    if functions -q fish_prompt; and not functions -q __braden_starship_fish_prompt
        functions -c fish_prompt __braden_starship_fish_prompt

        function fish_prompt
            if not contains -- --final-rendering $argv
                __braden_set_starship_git_dirty
            end

            __braden_starship_fish_prompt $argv
        end
    end
end
