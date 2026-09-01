#!/usr/bin/env bash

# aws-context.sh - Verify and display the active AWS identity
# Usage: ./scripts/aws-context.sh
#
# Requires AWS_PROFILE to be set
# Checks whether the selected profile's AWS credentials are valid
# Shows the active account, principal, user ID, profile, and region
# Optionally verifies EXPECTED_AWS_ACCOUNT_ID when it is set

# References:
# AWS CLI get-caller-identity
# AWS CLI environment variable configuration

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

# Assert failure if AWS CLI not found
command -v aws >/dev/null 2>&1 || \
    error "AWS CLI was not found"

# Assert failure if AWS_PROFILE is not set
[[ -n "${PROFILE}" ]] || \
    error "AWS_PROFILE is not set; run 'export AWS_PROFILE=<name>'"

# Check common AWS region variables for region setting
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-}}"

# Fall back to the AWS CLI configured region
[[ -n "${REGION}" ]] || \
    REGION="$(aws configure get region --profile "${PROFILE}" 2>/dev/null || true)"

# Default undefined region to "<not configured>"
REGION="${REGION:-<not configured>}"

# Ask AWS which identity the current credentials belong to
if ! IDENTITY="$(
    aws sts get-caller-identity \
        --profile "${PROFILE}" \
        --query "[Account,Arn,UserId]" \
        --output text 2>&1
)"; then
    printf "AWS authentication failed\n"
    printf "%s\n\n" "${IDENTITY}"
    printf "Run 'make login' to authenticate again\n"
    exit 1
fi

# Optionally require a specific AWS account
if [[ -n "${EXPECTED_AWS_ACCOUNT_ID:-}" ]]; then
    # Make sure the expected account ID looks valid
    if [[ ! "${EXPECTED_AWS_ACCOUNT_ID}" =~ ^[0-9]{12}$ ]]; then
        error "EXPECTED_AWS_ACCOUNT_ID must be a 12 digit AWS account ID"
    fi

    # Stop when the current account is not the expected account
    if [[ "${ACCOUNT_ID}" != "${EXPECTED_AWS_ACCOUNT_ID}" ]]; then
        printf "\nACCOUNT MISMATCH\n"
        printf "Expected: %s\n" "${EXPECTED_AWS_ACCOUNT_ID}"
        printf "Current:  %s\n\n" "${ACCOUNT_ID}"
        exit 1
    fi

    printf "Expected AWS account confirmed\n"
fi

# Stop after validation when quiet mode is requested
if [[ "${1:-}" == "--quiet" ]]; then
    exit 0
fi

# Import STS response into readable variables
read -r ACCOUNT_ID PRINCIPAL_ARN USER_ID <<< "${IDENTITY}"

# Display AWS context characteristics
printf "\nAWS Context\n"
printf '%s\n' "------------------------------------------------------------"
printf "Profile:     %s\n" "${PROFILE}"
printf "Account:     %s\n" "${ACCOUNT_ID}"
printf "Principal:   %s\n" "${PRINCIPAL_ARN}"
printf "User ID:     %s\n" "${USER_ID}"
printf "CLI Region:  %s\n" "${REGION}"
printf '%s\n\n' "------------------------------------------------------------"
