#!/usr/bin/env bash

# terraform-backend.sh - Initialize or migrate the main Terraform backend
# Usage: ./scripts/terraform-backend.sh <init|remote|local>
#
# Local state is used when s3-backend.tf is absent
# S3 state is used when s3-backend.tf is present

# References
# Terraform init
# Terraform partial backend configuration
# Terraform S3 backend

set -euo pipefail

export AWS_PAGER=""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TF_DIR="${ROOT_DIR}/terraform"
PROJECT_CONFIG="${ROOT_DIR}/config/project.tfvars"

BACKEND_TEMPLATE="${TF_DIR}/s3-backend.tf.example"
BACKEND_FILE="${TF_DIR}/s3-backend.tf"
BACKEND_DISABLED="${TF_DIR}/s3-backend.tf.disabled"

error() {
    printf 'ERROR: %s\n' "$1" >&2
    exit 1
}

read_project_value() {
    local key="$1"
    local value

    value="$(
        awk -v key="${key}" '
            $1 == key && $2 == "=" {
                value = $0
                sub(/^[^=]+=[[:space:]]*/, "", value)
                sub(/[[:space:]]*#.*/, "", value)
                gsub(/^"|"$/, "", value)
                print value
                exit
            }
        ' "${PROJECT_CONFIG}"
    )"

    [[ -n "${value}" ]] || \
        error "Could not read ${key} from config/project.tfvars"

    printf '%s' "${value}"
}

load_remote_backend() {
    command -v aws >/dev/null 2>&1 || \
        error "AWS CLI was not found"

    PROJECT_NAME="$(read_project_value project_name)"
    RESOURCE_PREFIX="$(read_project_value resource_prefix)"
    AWS_REGION="$(read_project_value aws_region)"

    ACCOUNT_ID="$(
        aws sts get-caller-identity \
            --query Account \
            --output text 2>/dev/null
    )" || error "Could not determine the active AWS account"

    STATE_BUCKET="${RESOURCE_PREFIX}-tfstate-${ACCOUNT_ID}"
    STATE_KEY="${PROJECT_NAME}/terraform.tfstate"
}

init_remote() {
    load_remote_backend

    terraform -chdir="${TF_DIR}" init \
        -input=false \
        -backend-config="bucket=${STATE_BUCKET}" \
        -backend-config="key=${STATE_KEY}" \
        -backend-config="region=${AWS_REGION}"
}

case "${1:-}" in
    init)
        if [[ -f "${BACKEND_FILE}" ]]; then
            init_remote
        else
            terraform -chdir="${TF_DIR}" init -input=false
        fi
        ;;

    remote)
        [[ -f "${BACKEND_TEMPLATE}" ]] || \
            error "S3 backend template was not found"

        load_remote_backend

        aws s3api head-bucket \
            --bucket "${STATE_BUCKET}" >/dev/null 2>&1 || \
            error "Remote state bucket was not found; deploy bootstrap first"

        created_backend=false

        if [[ ! -f "${BACKEND_FILE}" ]]; then
            cp "${BACKEND_TEMPLATE}" "${BACKEND_FILE}"
            created_backend=true
        fi

        # Migrate existing local state when present
        if [[ -f "${TF_DIR}/terraform.tfstate" ]]; then
            if ! terraform -chdir="${TF_DIR}" init \
                -migrate-state \
                -backend-config="bucket=${STATE_BUCKET}" \
                -backend-config="key=${STATE_KEY}" \
                -backend-config="region=${AWS_REGION}"; then

                if [[ "${created_backend}" == true ]]; then
                    rm -f "${BACKEND_FILE}"
                fi

                error "Could not migrate Terraform state to S3"
            fi
        else
            # Attach a fresh clone to an existing remote backend
            terraform -chdir="${TF_DIR}" init \
                -reconfigure \
                -input=false \
                -backend-config="bucket=${STATE_BUCKET}" \
                -backend-config="key=${STATE_KEY}" \
                -backend-config="region=${AWS_REGION}"
        fi

        printf '\nRemote S3 state enabled\n\n'
        ;;

    local)
        if [[ ! -f "${BACKEND_FILE}" ]]; then
            terraform -chdir="${TF_DIR}" init -input=false
            printf '\nLocal Terraform state is already enabled\n\n'
            exit 0
        fi

        # Rebuild the cached S3 backend before removing its configuration
        load_remote_backend

        terraform -chdir="${TF_DIR}" init \
            -reconfigure \
            -input=false \
            -backend-config="bucket=${STATE_BUCKET}" \
            -backend-config="key=${STATE_KEY}" \
            -backend-config="region=${AWS_REGION}"

        mv "${BACKEND_FILE}" "${BACKEND_DISABLED}"

        if ! terraform -chdir="${TF_DIR}" init -migrate-state; then
            mv "${BACKEND_DISABLED}" "${BACKEND_FILE}"
            error "Could not migrate Terraform state back to local storage"
        fi

        rm -f "${BACKEND_DISABLED}"

        printf '\nLocal Terraform state enabled\n\n'
        ;;

    *)
        error "Usage: $0 <init|remote|local>"
        ;;
esac
