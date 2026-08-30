#!/usr/bin/env bash

# backend-destroy.sh - Permanently remove remote state infrastructure
# Usage: ./scripts/backend-destroy.sh
#
# Requires the main Terraform stack to be fully destroyed first
# Migrates an empty remote main state back to local state when needed
# Permanently removes all S3 state versions before destroying the backend

# References:
# Terraform lifecycle prevent_destroy
# Terraform override files
# AWS S3 versioned object deletion
# AWS CLI delete-objects

set -euo pipefail

export AWS_PAGER=""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TF_DIR="${ROOT_DIR}/terraform"
BOOTSTRAP_DIR="${ROOT_DIR}/bootstrap"
PROJECT_CONFIG="${ROOT_DIR}/config/project.tfvars"

BACKEND_FILE="${TF_DIR}/s3-backend.tf"
BACKEND_SCRIPT="${ROOT_DIR}/scripts/terraform-backend.sh"
DESTROY_OVERRIDE="${BOOTSTRAP_DIR}/decommission_override.tf"

error() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

cleanup() {
    rm -f "${DESTROY_OVERRIDE}"
}

trap cleanup EXIT

# Assert AWS CLI is needed
command -v aws >/dev/null 2>&1 || \
    error "AWS CLI was not found"

# Assert Terraform CLI is needed
command -v terraform >/dev/null 2>&1 || \
    error "Terraform CLI was not found"

# The main stack must no longer track any infrastructure
MAIN_STATE="$(
    terraform -chdir="${TF_DIR}" state list 2>/dev/null || true
)"

if [[ -n "${MAIN_STATE}" ]]; then
    printf '\nMain Terraform state still contains:\n\n' >&2
    printf '%s\n\n' "${MAIN_STATE}" >&2
    error "Run 'make destroy' before destroying the state backend"
fi

# Read the backend coordinates created by bootstrap
STATE_BUCKET="$(
    terraform -chdir="${BOOTSTRAP_DIR}" \
        output -raw state_bucket_name 2>/dev/null
)" || error "Could not read the state bucket from bootstrap"

STATE_KEY="$(
    terraform -chdir="${BOOTSTRAP_DIR}" \
        output -raw state_key 2>/dev/null
)" || error "Could not read the state key from bootstrap"

printf '\nRemote State Decommission\n'
printf '%s\n' "------------------------------------------------------------"
printf ' Bucket: %s\n' "${STATE_BUCKET}"
printf ' State:  %s\n' "${STATE_KEY}"
printf '%s\n\n' "------------------------------------------------------------"

printf 'The main Terraform stack is empty\n'
printf 'This operation will permanently delete every stored state version\n\n'

# Confirm destruction using bucket name
printf 'Type the bucket name to confirm destruction:\n> '
read -r CONFIRMATION
[[ "${CONFIRMATION}" == "${STATE_BUCKET}" ]] || \
    error "Confirmation did not match the state bucket name"

# Move the empty main state away from S3 before destroying its backend
if [[ -f "${BACKEND_FILE}" ]]; then
    printf '\nMigrating empty main state back to local storage\n\n'
    "${BACKEND_SCRIPT}" local
fi

printf 'Removing all state object versions and delete markers\n'

# A versioned bucket must have every retained version permanently deleted
while true; do
    VERSION_COUNT="$(
        aws s3api list-object-versions \
            --bucket "${STATE_BUCKET}" \
            --query 'length(Versions || `[]`)' \
            --output text
    )"

    [[ "${VERSION_COUNT}" -gt 0 ]] || break

    DELETE_PAYLOAD="$(
        aws s3api list-object-versions \
            --bucket "${STATE_BUCKET}" \
            --query '{Objects: Versions[].{Key:Key,VersionId:VersionId},Quiet:`true`}' \
            --output json
    )"

    aws s3api delete-objects \
        --bucket "${STATE_BUCKET}" \
        --delete "${DELETE_PAYLOAD}" \
        >/dev/null
done

# A versioned bucket must have every marker permanently deleted
while true; do
    MARKER_COUNT="$(
        aws s3api list-object-versions \
            --bucket "${STATE_BUCKET}" \
            --query 'length(DeleteMarkers || `[]`)' \
            --output text
    )"

    [[ "${MARKER_COUNT}" -gt 0 ]] || break

    DELETE_PAYLOAD="$(
        aws s3api list-object-versions \
            --bucket "${STATE_BUCKET}" \
            --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId},Quiet:`true`}' \
            --output json
    )"

    aws s3api delete-objects \
        --bucket "${STATE_BUCKET}" \
        --delete "${DELETE_PAYLOAD}" \
        >/dev/null
done

# Confirm no remaining versions
REMAINING_VERSIONS="$(
    aws s3api list-object-versions \
        --bucket "${STATE_BUCKET}" \
        --query 'length(Versions || `[]`)' \
        --output text
)"
[[ "${REMAINING_VERSIONS}" == "0" ]] || \
    error "The state bucket still contains object versions"

# Confirm no remaining markers
REMAINING_MARKERS="$(
    aws s3api list-object-versions \
        --bucket "${STATE_BUCKET}" \
        --query 'length(DeleteMarkers || `[]`)' \
        --output text
)"
[[ "${REMAINING_MARKERS}" == "0" ]] || \
    error "The state bucket still contains delete markers"

printf 'State bucket contents permanently removed\n'

# Temporarily disable the Terraform destruction guard with a file overriding the prevent_destroy
cat > "${DESTROY_OVERRIDE}" <<'EOF'
# Generated temporarily by backend-destroy.sh
# Allows intentional destruction of the protected state bucket

resource "aws_s3_bucket" "state" {
  lifecycle {
    prevent_destroy = false
  }
}
EOF

printf 'Destroying remote state infrastructure\n\n'
terraform -chdir="${BOOTSTRAP_DIR}" init -input=false
terraform -chdir="${BOOTSTRAP_DIR}" destroy \
    -auto-approve \
    -var-file="../config/project.tfvars"

printf '\nRemote state infrastructure destroyed\n'
printf 'The project is now configured for local state only\n\n'
