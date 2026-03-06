# =============================================================================
# Nx Completions
# =============================================================================

function __braden_nx_completion_enabled
    set -l phoenix_root "$HOME/Development/Phoenix"
    test -x "$phoenix_root/node_modules/.bin/nx"
end

function __braden_nx_cache_dir
    echo "$HOME/.cache/fish/nx"
end

function __braden_nx_cache_is_fresh --argument-names file_path
    test -f "$file_path"; or return 1

    set -l now (date +%s)
    set -l modified_at (stat -f %m "$file_path" 2>/dev/null)
    or return 1

    test (math "$now - $modified_at") -lt 300
end

function __braden_nx_refresh_completion_cache
    __braden_nx_completion_enabled; or return 1

    set -l cache_dir (__braden_nx_cache_dir)
    set -l projects_file "$cache_dir/projects.txt"
    set -l targets_file "$cache_dir/targets.txt"
    set -l mapping_file "$cache_dir/project-targets.tsv"

    if __braden_nx_cache_is_fresh "$projects_file"
        and __braden_nx_cache_is_fresh "$targets_file"
        and __braden_nx_cache_is_fresh "$mapping_file"
        return 0
    end

    set -l phoenix_root "$HOME/Development/Phoenix"
    set -l helper_script "$HOME/.config/fish/completions/_braden_nx_workspace.js"

    mkdir -p "$cache_dir"

    set -l temp_json (mktemp)
    set -l temp_projects (mktemp)
    set -l temp_targets (mktemp)
    set -l temp_mapping (mktemp)

    env PATH="$PATH" HOME="$HOME" bash -c '
        cd "$1" || exit 1
        shift
        node "$@"
    ' bash "$phoenix_root" "$helper_script" >"$temp_json" 2>/dev/null
    or begin
        rm -f "$temp_json" "$temp_projects" "$temp_targets" "$temp_mapping"
        return 1
    end

    jq -r 'keys[]' "$temp_json" >"$temp_projects"
    or begin
        rm -f "$temp_json" "$temp_projects" "$temp_targets" "$temp_mapping"
        return 1
    end

    jq -r 'to_entries[] | .key as $project | .value[] | [$project, .] | @tsv' "$temp_json" | sort -u >"$temp_mapping"
    or begin
        rm -f "$temp_json" "$temp_projects" "$temp_targets" "$temp_mapping"
        return 1
    end

    jq -r '[.[] | .[]] | unique[]' "$temp_json" >"$temp_targets"
    or begin
        rm -f "$temp_json" "$temp_projects" "$temp_targets" "$temp_mapping"
        return 1
    end

    mv "$temp_projects" "$projects_file"
    and mv "$temp_targets" "$targets_file"
    and mv "$temp_mapping" "$mapping_file"

    rm -f "$temp_json"
end

function __braden_nx_projects
    __braden_nx_refresh_completion_cache; or return 1
    cat (__braden_nx_cache_dir)/projects.txt
end

function __braden_nx_targets
    __braden_nx_refresh_completion_cache; or return 1
    cat (__braden_nx_cache_dir)/targets.txt
end

function __braden_nx_project_target_pairs
    __braden_nx_refresh_completion_cache; or return 1
    cat (__braden_nx_cache_dir)/project-targets.tsv
end

function __braden_nx_known_subcommands
    printf "%s\n" \
        add \
        affected \
        configure-ai-agents \
        connect \
        daemon \
        download-cloud-client \
        exec \
        fix-ci \
        format:check \
        format:write \
        generate \
        graph \
        import \
        init \
        list \
        login \
        logout \
        mcp \
        migrate \
        record \
        release \
        repair \
        report \
        reset \
        run \
        run-many \
        show \
        start-agent \
        start-ci-run \
        stop-all-agents \
        sync \
        sync:check \
        view-logs \
        watch
end

function __braden_nx_subcommands_with_desc
    printf "%s\t%s\n" \
        affected "Run targets for affected projects" \
        daemon "Inspect or start the Nx daemon" \
        exec "Run an arbitrary command as an Nx target" \
        format:check "Check formatting across the workspace" \
        format:write "Write formatting fixes across the workspace" \
        generate "Generate or update source code" \
        graph "Open the dependency graph" \
        list "List installed or available plugins" \
        release "Run versioning and publishing flows" \
        repair "Repair outdated Nx configuration" \
        report "Print Nx environment details" \
        reset "Clear Nx cache and daemon state" \
        run "Run a target for one project" \
        run-many "Run a target for multiple projects" \
        show "Show workspace project information" \
        sync "Run workspace sync generators" \
        sync:check "Check whether sync generators would change files" \
        watch "Watch projects and run commands"
end

function __braden_nx_targets_with_desc
    __braden_nx_targets | awk '{ printf "%s\tWorkspace target\n", $0 }'
end

function __braden_nx_run_specs
    __braden_nx_project_target_pairs | awk -F '\t' '{ printf "%s:%s\t%s target for %s\n", $1, $2, $2, $1 }'
end

function __braden_nx_projects_for_target --argument-names target_name
    __braden_nx_project_target_pairs | awk -F '\t' -v target_name="$target_name" '$2 == target_name { print $1 }'
end

function __braden_nx_non_option_args
    for token in (commandline -pxc)[2..-1]
        if string match -qr '^-' -- $token
            continue
        end

        echo $token
    end
end

function __braden_nx_first_non_option_arg
    set -l args (__braden_nx_non_option_args)
    test (count $args) -gt 0; or return 1
    echo $args[1]
end

function __braden_nx_is_target_command
    set -l first_arg (__braden_nx_first_non_option_arg)
    or return 1

    contains -- $first_arg (__braden_nx_known_subcommands)
    and return 1

    contains -- $first_arg (__braden_nx_targets)
end

function __braden_nx_projects_for_first_target
    set -l first_arg (__braden_nx_first_non_option_arg)
    or return 1

    __braden_nx_projects_for_target $first_arg
end

function __braden_nx_previous_token_is
    set -l tokens (commandline -opc)
    test (count $tokens) -gt 0; or return 1
    contains -- $tokens[-1] $argv
end

function __braden_nx_csv_candidates --argument-names candidate_type
    set -l prefix (string replace -r '[^,]*$' '' -- (commandline -ct))
    set -l candidates

    switch $candidate_type
        case projects
            set candidates (__braden_nx_projects)
        case targets
            set candidates (__braden_nx_targets)
        case '*'
            return 1
    end

    for candidate in $candidates
        echo "$prefix$candidate"
    end
end

complete -c nx -e

complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_use_subcommand' -a '(__braden_nx_subcommands_with_desc)'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_use_subcommand' -a '(__braden_nx_targets_with_desc)'

complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run; and __fish_is_nth_token 2' -a '(__braden_nx_run_specs)'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_is_nth_token 2; and __braden_nx_is_target_command' -a '(__braden_nx_projects_for_first_target)'

complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many affected' -s t -xa '(__braden_nx_csv_candidates targets)' -d 'Targets to run'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many affected' -l target -xa '(__braden_nx_csv_candidates targets)' -d 'Targets to run'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many affected' -l targets -xa '(__braden_nx_csv_candidates targets)' -d 'Targets to run'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many affected; and __braden_nx_previous_token_is -t --target --targets' -a '(__braden_nx_csv_candidates targets)'

complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many' -s p -xa '(__braden_nx_csv_candidates projects)' -d 'Projects to run'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many' -l projects -xa '(__braden_nx_csv_candidates projects)' -d 'Projects to run'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many affected' -l exclude -xa '(__braden_nx_csv_candidates projects)' -d 'Projects to exclude'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many; and __braden_nx_previous_token_is -p --projects' -a '(__braden_nx_csv_candidates projects)'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from run-many affected; and __braden_nx_previous_token_is --exclude' -a '(__braden_nx_csv_candidates projects)'

complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from show; and __fish_is_nth_token 2' -a "project\tShow resolved configuration for a project"
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from show; and __fish_is_nth_token 2' -a "projects\tShow workspace projects"
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from show; and __fish_seen_subcommand_from project; and __fish_is_nth_token 3' -a '(__braden_nx_projects)'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from show; and __fish_seen_subcommand_from projects' -l with-target -xa '(__braden_nx_csv_candidates targets)' -d 'Only show projects with a target'
complete -f -c nx -n '__braden_nx_completion_enabled; and __fish_seen_subcommand_from show; and __fish_seen_subcommand_from projects; and __braden_nx_previous_token_is --with-target' -a '(__braden_nx_csv_candidates targets)'
