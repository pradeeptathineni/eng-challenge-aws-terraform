#!/usr/bin/env bash

# aws-context.sh - Verify and display the active AWS identity
# Usage: ./scripts/aws-context.sh
#
# Requires AWS_PROFILE to be set
# Checks whether the selected profile's AWS credentials are valid
# Shows the active account, principal, user ID, profile, and region
# Optionally verifies EXPECTED_AWS_ACCOUNT_ID when it is set

# References
# AWS CLI get-caller-identity
# AWS CLI environment variable configuration

set -euo pipefail

# Disable the AWS CLI output pager
export AWS_PAGER=""

PROFILE="${AWS_PROFILE:-}"

error() {
    printf "ERROR: %s\n" "$1" >&2
    exit 1
}

# Make sure the AWS CLI is installed
command -v aws >/dev/null 2>&1 || \
    error "AWS CLI was not found"

# Require the AWS profile to be selected explicitly
[[ -n "${PROFILE}" ]] || \
    error "AWS_PROFILE is not set"


# Check common AWS region settings
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"

# Fall back to the AWS CLI configured region
if [[ -z "${REGION}" ]]; then
    REGION="$(aws configure get region --profile "${PROFILE}" 2>/dev/null || true)"
fi

# Show a clear value when no CLI region is configured
REGION="${REGION:-<not configured>}"

# Ask AWS which identity the current credentials belong to
if ! IDENTITY="$(
    aws sts get-caller-identity \
        --profile "${PROFILE}" \
        --query '[Account,Arn,UserId]' \
        --output text 2>&1
)"; then
    printf "\nAWS authentication failed\n\n" >&2
    printf "%s\n\n" "${IDENTITY}" >&2
    printf "Run 'make login' to authenticate again\n" >&2
    exit 1
fi

# Split the STS response into readable values
read -r ACCOUNT_ID PRINCIPAL_ARN USER_ID <<< "${IDENTITY}"

printf "\n"
printf "AWS Context\n"
printf '%s\n' "------------------------------------------------------------"
printf "Profile:    %s\n" "${PROFILE}"
printf "Account:    %s\n" "${ACCOUNT_ID}"
printf "Principal:  %s\n" "${PRINCIPAL_ARN}"
printf "User ID:    %s\n" "${USER_ID}"
printf "CLI Region: %s\n" "${REGION}"
printf '%s\n' "------------------------------------------------------------"

# Optionally require a specific AWS account
if [[ -n "${EXPECTED_AWS_ACCOUNT_ID:-}" ]]; then
    # Make sure the expected account ID looks valid
    if [[ ! "${EXPECTED_AWS_ACCOUNT_ID}" =~ ^[0-9]{12}$ ]]; then
        error "EXPECTED_AWS_ACCOUNT_ID must be a 12 digit AWS account ID"
    fi

    # Stop when the current account is not the expected account
    if [[ "${ACCOUNT_ID}" != "${EXPECTED_AWS_ACCOUNT_ID}" ]]; then
        printf "\nACCOUNT MISMATCH\n" >&2
        printf "Expected: %s\n" "${EXPECTED_AWS_ACCOUNT_ID}" >&2
        printf "Current:  %s\n\n" "${ACCOUNT_ID}" >&2
        exit 1
    fi

    printf "Expected AWS account confirmed\n"
fi

printf "\n"
