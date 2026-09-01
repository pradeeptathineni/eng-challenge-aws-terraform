#!/usr/bin/env bash

# aws-profile.sh - Selects or configures the AWS profile used by the project
# Usage: ./scripts/aws-profile.sh
#
# Selects an existing AWS CLI profile or configures a new one
# Aligns the profile region with config/project.tfvars
# Stores the selected profile name for future Make workflows

# References:
# AWS CLI configuration
# AWS CLI list-profiles
# AWS CLI IAM Identity Center configuration
# AWS CLI local development login

# Define immediate exit behavior
# -e, exit on any command non-zero exit code
# -u, exit on not defined variable reference
# -o pipefail, exit on any non-zero exit code within a pipeline
set -euo pipefail

# Preserve stdout for the selected profile result
exec 3>&1

# Send normal interactive output to stderr
exec 1>&2

# Disable the AWS CLI output pager
export AWS_PAGER=""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_CONFIG="${ROOT_DIR}/config/project.tfvars"

# Handle error with message and failure exit
error() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

# Assert failure if AWS CLI not found
command -v aws >/dev/null 2>&1 || \
    error "AWS CLI was not found"

# Prefer the project region exported by Make
PROJECT_REGION="${AWS_REGION:-}"

# Fall back to the committed project configuration when run directly
if [[ -z "${PROJECT_REGION}" ]]; then
    PROJECT_REGION="$(
        awk '
            $1 == "aws_region" && $2 == "=" {
                value = $3
                gsub(/"/, "", value)
                print value
                exit
            }
        ' "${PROJECT_CONFIG}"
    )"
fi

# Assert failure on undefined AWS region
[[ -n "${PROJECT_REGION}" ]] || \
    error "Could not determine the project AWS region"

# List currently configured AWS profiles
PROFILES="$(aws configure list-profiles)"
printf '\nConfigured AWS Profiles\n'
printf '%s\n' "------------------------------------------------------------"
printf '%s\n' "${PROFILES:-<none configured>}"
printf '%s\n\n' "------------------------------------------------------------"

# Select profile automatically when AUTO=1
if [[ "${AUTO:-0}" == "1" ]]; then
    PROFILE="${AWS_PROFILE:-}"
else
    # Prompt user to select profile to use
    if [[ -n "${AWS_PROFILE:-}" ]]; then
        printf 'Select/create AWS profile name [%s] (enter to select): ' "${AWS_PROFILE}"
    else
        printf 'Select/create AWS profile name: '
    fi
    read -r PROFILE_INPUT

    # If profile input is empty, default to AWS_PROFILE
    PROFILE="${PROFILE_INPUT:-${AWS_PROFILE:-}}"
fi

# Assert failure for undefined AWS profile
# Either due to empty input or empty AWS_PROFILE
[[ -n "${PROFILE}" ]] || \
    error "AWS_PROFILE is not set; run 'export AWS_PROFILE=<name>'"

# Assert failure for invalid AWS profile naming convention
[[ "${PROFILE}" =~ ^[A-Za-z0-9._-]+$ ]] || \
    error "Profile name may contain only alphanumeric, periods, underscores, and hyphens"

# Guide user in configuration if selected profile does not exist
if ! echo "${PROFILES}" | grep -Fxq "${PROFILE}"; then
    printf '\nProfile [%s] is not configured\n\n' "${PROFILE}"
    printf 'Choose a configuration method:\n\n'
    printf '  1) IAM Identity Center / SSO\n'
    printf '     $ aws configure sso --profile "${PROFILE}"\n\n'
    printf '  2) AWS local development login\n'
    printf '     $ aws configure set region "${PROJECT_REGION}" --profile "${PROFILE}"\n\n'
    printf '  3) Long-lived IAM access keys\n'
    printf '     $ aws configure --profile "${PROFILE}"\n\n'

    # Perform the AWS profile configuration according to a selected method
    # Loop until user inputs a valid method choice
    while : ; do
        printf "Selection: "
        read -r CONFIGURE_METHOD
        case "${CONFIGURE_METHOD}" in
            1)
            # Configure for IAM Identity Center / SSO
                aws configure sso --profile "${PROFILE}"
                break
                ;;
            2)
            # Configure for AWS local development login
                # Assert failure if installed AWS CLI version does not support "aws login"
                if ! aws login help >/dev/null 2>&1; then
                    aws --version
                    error "AWS CLI 2.32.0 or newer is required for 'aws login'"
                fi

                # Create the named profile with the project region
                # Authentication itself remains the responsibility of "make login"
                aws configure set region "${PROJECT_REGION}" --profile "${PROFILE}"
                break
                ;;
            3)
            # Configure for long-lived IAM access keys
                aws configure --profile "${PROFILE}"
                break
                ;;
            *)
                printf "  Invalid choice; choose 1, 2, or 3\n\n"
                ;;
        esac
    done
fi

# Retrieve profile's configured aws region
# Redirect stderr to null for cleanliness
# Avoid failure exit codes using "true" so script continues
PROFILE_REGION="$(
    aws configure get region \
        --profile "${PROFILE}" \
        2>/dev/null || true
)"

# Default to project region definition if profile/project region definitions are different
if [[ -n "${PROFILE_REGION}" && "${PROFILE_REGION}" != "${PROJECT_REGION}" ]]; then
    printf '\nNote: Project workflows will use %s instead of the profile region\n' \
        "${PROJECT_REGION}"
fi

# Display selected profile characteristics
printf '\nAWS Profile Selected\n'
printf '%s\n' "------------------------------------------------------------"
printf 'Profile:         %s\n' "${PROFILE}"
printf 'Profile Region:  %s\n' "${PROFILE_REGION:-<not configured>}"
printf 'Project Region:  %s\n' "${PROJECT_REGION}"
printf '%s\n\n' "------------------------------------------------------------"

# Machine-readable result for Make and shell composition
printf '%s\n' "${PROFILE}" >&3
