#!/usr/bin/env bash

# This script generates template apps and tests them by building and running the flake for each app
debug() {
    echo "$@" >&2
}

echo "Starting template apps testing script..."

# Function to collect template app names
get_current_system() {
    debug "Getting current system..."
    nix config show --json 2>/dev/null | jq -r '.system.defaultValue'
}

current_system=$(get_current_system)

get_template_apps() {
    debug "Discovering template apps for system: ${current_system}..."
    # Use nix eval to get app names, excluding default and process-template
    nix eval --json .#apps.${current_system} 2>/dev/null | jq -r 'keys[]' | grep -v -E '^(default|process-templates)$'
}

# Function to test a single template app
test_template_app() {
    local app_name="$1"
    local target_dir="./metatemplates/generated/${app_name}"

    debug "Testing template app: ${app_name}"

    # Generate the template
    nix run .#"${app_name}" -- --target "${target_dir}"

    # Test the development environment
    if [ -d "${target_dir}" ]; then
        debug "Testing development environment for ${app_name}..."
        (cd "${target_dir}" && git add . && nix develop --command true)
        debug "Development environment test completed for ${app_name}"
    else
        debug "Error: Target directory ${target_dir} was not created"
        return 1
    fi
}

# Main execution
main() {
    debug "Starting main execution..."
    # Get all template apps
    template_apps=$(get_template_apps)
    debug "Found template apps: ${template_apps}"
    # Test each template app
    for app in ${template_apps}; do
        test_template_app "${app}"
    done
}

# Run the script
main
echo "Template apps testing script completed."
