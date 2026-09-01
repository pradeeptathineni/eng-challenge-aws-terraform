#!/usr/bin/env bash

# aws-login.sh - Log into AWS using the CLI
# Usage: ./scripts/aws-login.sh
#
# Requires AWS_PROFILE to be set
# Reuses valid credentials when already authenticated
# Uses AWS SSO when the profile uses IAM Identity Center
# Uses "aws login" for local development login profiles

# References:
# AWS CLI IAM Identity Center authentication
# AWS CLI local development login
# AWS CLI export-credentials
# AWS CLI get-caller-identity

# Define immediate exit behavior
# -e, exit on any command non-zero exit code
# -u, exit on not defined variable reference
# -o pipefail, exit on any non-zero exit code within a pipeline
set -euo pipefail

# Disable the AWS CLI output pager
export AWS_PAGER=""

PROFILE="${AWS_PROFILE:-}"

# Handle error with message and failure exit
error() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

# Assert failure if AWS CLI not installed
command -v aws >/dev/null 2>&1 || \
    error "AWS CLI was not found"

# Assert failure if AWS_PROFILE not set
[[ -n "${PROFILE}" ]] || \
    error "AWS_PROFILE is not set; run 'export AWS_PROFILE=<name>'"

# Retrieve a value from the selected AWS profile
get_profile_config() {
    aws configure get "$1" \
        --profile "${PROFILE}" \
        2>/dev/null || true
}

# Retrieve AWS profile configuration values
SSO_SESSION="$(get_profile_config sso_session)"
SSO_START_URL="$(get_profile_config sso_start_url)"
LOGIN_SESSION="$(get_profile_config login_session)"
STATIC_ACCESS_KEY="$(get_profile_config aws_access_key_id)"

# Authenticate according to selected profile configuration
if [[ -n "${SSO_SESSION}" || -n "${SSO_START_URL}" ]]; then
    AUTH_METHOD="IAM Identity Center"

    # Reuse SSO credentials when they can still be resolved
    if aws configure export-credentials \
        --profile "${PROFILE}" \
        --format process \
        >/dev/null 2>&1
    then
        SESSION_STATUS="Existing credentials reused"
    else
        # Establish a new usable SSO session
        aws sso login --profile "${PROFILE}"
        SESSION_STATUS="New session established"
    fi

elif [[ -n "${LOGIN_SESSION}" ]]; then
    AUTH_METHOD="AWS local development login"

    # Reuse valid local development credentials
    if aws sts get-caller-identity \
        --profile "${PROFILE}" \
        >/dev/null 2>&1
    then
        SESSION_STATUS="Existing credentials reused"
    else
        # Establish a new local development session
        aws login --profile "${PROFILE}"
        SESSION_STATUS="New session established"
    fi

elif [[ -n "${STATIC_ACCESS_KEY}" ]]; then
    AUTH_METHOD="IAM access key credentials"

    # Verify configured static credentials
    if aws sts get-caller-identity \
        --profile "${PROFILE}" \
        >/dev/null 2>&1
    then
        SESSION_STATUS="Existing credentials valid"
    else
        error "Configured IAM access key credentials are not valid
Run 'make profile' first"
    fi

else
    AUTH_METHOD="AWS local development login"

    # Reuse valid credentials when already available
    if aws sts get-caller-identity \
        --profile "${PROFILE}" \
        >/dev/null 2>&1
    then
        SESSION_STATUS="Existing credentials reused"
    else
        # Assert failure if installed AWS CLI does not support "aws login"
        if ! aws login help >/dev/null 2>&1; then
            aws --version
            error "AWS CLI 2.32.0 or newer is required for 'aws login'"
        fi

        # Establish a new local development session
        aws login --profile "${PROFILE}"
        SESSION_STATUS="New session established"
    fi
fi

# Display AWS login characteristics
printf "\nAWS Login\n"
printf '%s\n' "------------------------------------------------------------"
printf 'Profile:  %s\n' "${PROFILE}"
printf 'Method:   %s\n' "${AUTH_METHOD}"
printf 'Session:  %s\n' "${SESSION_STATUS}"
printf '%s\n\n' "------------------------------------------------------------"
