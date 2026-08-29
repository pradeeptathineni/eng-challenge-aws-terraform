#!/usr/bin/env bash

# aws-login.sh - Log into AWS for local development
# Usage: ./scripts/aws-login.sh [profile]
#
# Uses AWS SSO when the selected profile is configured for IAM Identity Center
# Uses `aws login` otherwise
# Verifies the active AWS identity after login

# References:
# AWS CLI local development login
# AWS CLI IAM Identity Center authentication

set -euo pipefail

PROFILE="${1:-${AWS_PROFILE:-default}}"
CONTEXT_SCRIPT="$(dirname "$0")/aws-context.sh"

error() {
  printf "ERROR: %s\n" "$1" >&2
  exit 1
}

# Make sure the AWS CLI is installed
command -v aws >/dev/null 2>&1 || \
  error "AWS CLI was not found"

# Make sure the context helper exists
[[ -x "${CONTEXT_SCRIPT}" ]] || \
  error "AWS context helper was not found or is not executable"

printf "\nAWS Login\n"
printf "------------------------------------------------------------\n"
printf "Profile: %s\n" "${PROFILE}"
printf "------------------------------------------------------------\n\n"

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

# Make the selected profile available to downstream commands
export AWS_PROFILE="${PROFILE}"

printf "\nLogin complete\n"

# Verify and display the authenticated AWS identity
"${CONTEXT_SCRIPT}"