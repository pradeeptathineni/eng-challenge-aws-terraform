#!/usr/bin/env bash

# aws-login.sh - Log into AWS for local development
# Usage: ./scripts/aws-login.sh
#
# Requires AWS_PROFILE to be set
# Uses AWS SSO when the profile uses IAM Identity Center
# Uses `aws login` otherwise

# References:
# AWS CLI local development login
# AWS CLI IAM Identity Center authentication

set -euo pipefail

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

printf "\nAWS Login\n"
printf '%s\n' "------------------------------------------------------------"
printf "Profile: %s\n" "${PROFILE}"
printf '%s\n\n' "------------------------------------------------------------"

# Check whether the profile uses IAM Identity Center
SSO_SESSION="$(aws configure get sso_session --profile "${PROFILE}" 2>/dev/null || true)"
SSO_START_URL="$(aws configure get sso_start_url --profile "${PROFILE}" 2>/dev/null || true)"

if [[ -n "${SSO_SESSION}" || -n "${SSO_START_URL}" ]]; then
    printf "Authentication: AWS IAM Identity Center\n\n"
    aws sso login --profile "${PROFILE}"
else
    printf "Authentication: AWS local development login\n\n"
    aws login --profile "${PROFILE}"
fi

# Make the selected profile available to the context helper
export AWS_PROFILE="${PROFILE}"

printf "\nLogin complete\n"
