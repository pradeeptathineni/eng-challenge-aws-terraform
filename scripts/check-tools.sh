#!/usr/bin/env bash

# check-tools.sh - Assert required local tools and versions are installed
# Usage: ./scripts/check-tools.sh
#
# Tool availability is checked first
# Tools with minimum versions are then checked against that requirement

# Define immediate exit behavior
# -e, exit on any command non-zero exit code
# -u, exit on not defined variable reference
# -o pipefail, exit on any non-zero exit code within a pipeline
set -euo pipefail

# Required local tools
# Version-agnostic tool format: "tool name"
# Version-relevant tool format: "tool name|minimum version|version command|version regex"
TOOL_SPECS=(
    "bash"
    "git"
    "aws|2.32.0|aws --version|aws-cli/([0-9]+([.][0-9]+)*)"
    "terraform|1.16.0|terraform version|Terraform v([0-9]+([.][0-9]+)*)"
    "make"
    "awk"
    "curl"
)

# Store tool versions for final display
TOOL_RESULTS=()

# Handle error with message and failure exit
error() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

# Compare numeric version components
# Supports versions such as A, A.B, A.B.C, and longer
version_at_least() {
    local current="$1"
    local required="$2"

    awk -v current="${current}" -v required="${required}" '
        BEGIN {
            current_count = split(current, c, ".")
            required_count = split(required, r, ".")
            count = current_count > required_count \
                ? current_count \
                : required_count

            for (i = 1; i <= count; i++) {
                current_part = (i <= current_count ? c[i] : 0) + 0
                required_part = (i <= required_count ? r[i] : 0) + 0

                if (current_part > required_part)
                    exit 0

                if (current_part < required_part)
                    exit 1
            }

            exit 0
        }
    '
}

# Verify a required tool
check_tool() {
    local tool="$1"
    local minimum_version="$2"
    local version_command="$3"
    local version_regex="$4"
    local version_output
    local current_version="available"

    command -v "${tool}" >/dev/null 2>&1 || \
        error "${tool} is required but was not found"

    # Skip version checking when no minimum is required
    if [[ -z "${minimum_version}" ]]; then
        TOOL_RESULTS+=("${tool}|${current_version}")
        return
    fi

    version_output="$(${version_command} 2>&1)"

    if [[ ! "${version_output}" =~ ${version_regex} ]]; then
        error "Could not determine ${tool} version"
    fi

    current_version="${BASH_REMATCH[1]}"

    version_at_least "${current_version}" "${minimum_version}" || \
        error "${tool} ${minimum_version} or newer is required"

    TOOL_RESULTS+=(
        "${tool}|${current_version} (minimum ${minimum_version})"
    )
}

# Verify all required tools
for spec in "${TOOL_SPECS[@]}"; do
    IFS='|' read -r \
        tool \
        minimum_version \
        version_command \
        version_regex <<< "${spec}"

    check_tool \
        "${tool}" \
        "${minimum_version}" \
        "${version_command}" \
        "${version_regex}"
done

# Display required tool characteristics
printf "\nRequired Tools\n"
printf '%s\n' "------------------------------------------------------------"
for result in "${TOOL_RESULTS[@]}"; do
    IFS='|' read -r tool status <<< "${result}"
    printf '%-15s %s\n' "${tool}:" "${status}"
done
printf '%s\n\n' "------------------------------------------------------------"
