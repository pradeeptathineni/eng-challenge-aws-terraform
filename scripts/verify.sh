#!/usr/bin/env bash

# verify.sh - Verify the deployed application end to end
# Usage: ./scripts/verify.sh
#
# Verifies Terraform outputs, ALB target health, HTTP redirect,
# and the final HTTPS application response

# References:
# Terraform output command
# AWS CLI describe-load-balancers
# AWS CLI describe-target-groups
# AWS CLI describe-target-health
# curl certificate verification

set -euo pipefail

export AWS_PAGER=""

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform"

FULL_EXPECTED_CONTENT="""\
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>AWS Terraform Engineering Challenge</title>
</head>
<body>
    <h1>AWS Terraform Engineering Challenge</h1>
    <p>Private EC2 web server is running</p>
</body>
</html>
"""
EXPECTED_CONTENT="Private EC2 web server is running"

error() {
    printf "ERROR: %s\n" "$1" >&2
    exit 1
}

# Assert failure if AWS CLI not found
command -v aws >/dev/null 2>&1 || \
    error "AWS CLI was not found"

# Assert failure if Terraform CLI not found
command -v terraform >/dev/null 2>&1 || \
    error "Terraform CLI was not found"

# Assert failure if curl not found
command -v curl >/dev/null 2>&1 || \
    error "curl was not found"

# Begin verification message box
printf "\nDeployment Verification\n"
printf '%s\n' "------------------------------------------------------------"

# Read alb_dns_name from Terraform state
ALB_DNS="$(
    terraform -chdir="${TF_DIR}" output -raw alb_dns_name 2>/dev/null
)" || error "Could not read alb_dns_name from Terraform state"

# Assert failure if alb_dns_name returns empty
[[ -n "${ALB_DNS}" ]] || \
    error "Terraform returned an empty ALB DNS name"

# Affirm successful Terraform IaC for ALB
printf ' ALB DNS:           %s\n' "${ALB_DNS}"

# Read ec2_private_ip from Terraform state
EC2_PRIVATE_IP="$(
    terraform -chdir="${TF_DIR}" output -raw ec2_private_ip 2>/dev/null
)" || error "Could not read ec2_private_ip from Terraform state"

# Assert failure if ec2_private_ip returns empty
[[ -n "${EC2_PRIVATE_IP}" ]] || \
    error "Terraform returned an empty EC2 private IP"

# Affirm successful Terraform IaC for EC2 instance
printf ' EC2 Private IP:    %s\n' "${EC2_PRIVATE_IP}"

# Find the load balancer represented by the Terraform output
ALB_ARN="$(
    aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?DNSName=='${ALB_DNS}'].LoadBalancerArn | [0]" \
        --output text
)"

# Assert failure if ALB not found in AWS
[[ -n "${ALB_ARN}" && "${ALB_ARN}" != "None" ]] || \
    error "Could not find the application load balancer in AWS"

# Find the target group connected to the load balancer
TARGET_GROUP_ARN="$(
    aws elbv2 describe-target-groups \
        --load-balancer-arn "${ALB_ARN}" \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text
)"

# Assert failure if ALB target group not found
[[ -n "${TARGET_GROUP_ARN}" && "${TARGET_GROUP_ARN}" != "None" ]] || \
    error "Could not find a target group for the application load balancer"

# Confirm every registered target is healthy
TARGET_STATES="$(
    aws elbv2 describe-target-health \
        --target-group-arn "${TARGET_GROUP_ARN}" \
        --query 'TargetHealthDescriptions[].TargetHealth.State' \
        --output text
)"

# Assert failure is no registered targets found
[[ -n "${TARGET_STATES}" && "${TARGET_STATES}" != "None" ]] || \
    error "No registered targets were found"

# Assert failure if any registered target is not "healthy"
for state in ${TARGET_STATES}; do
    [[ "${state}" == "healthy" ]] || \
        error "A load balancer target is ${state}"
done

# Affirm successful AWS targets
printf ' Target(s) health:  %s\n' "healthy"

# Confirm HTTP redirects to HTTPS
read -r HTTP_STATUS REDIRECT_URL <<< "$(
    curl \
        --silent \
        --show-error \
        --output /dev/null \
        --connect-timeout 10 \
        --max-time 30 \
        --write-out '%{http_code} %{redirect_url}' \
        "http://${ALB_DNS}"
)"

# Assert failure if HTTP status is not 301 redirect
[[ "${HTTP_STATUS}" == "301" ]] || \
    error "Expected HTTP 301 redirect but received ${HTTP_STATUS}"

# Assert failure if HTTP redirects to unexpected HTTPS endpoint
[[ "${REDIRECT_URL}" == "https://${ALB_DNS}"* ]] || \
    error "HTTP did not redirect to the expected HTTPS endpoint"

# Affirm successful web server redirect
printf ' HTTP redirect:     %s\n' "301 to HTTPS"

# Verify the final HTTPS response
# Certificate verification is skipped because the deployment uses a self-signed certificate
HTTPS_BODY="$(
    curl \
        --insecure \
        --fail \
        --silent \
        --show-error \
        --connect-timeout 10 \
        --max-time 30 \
        "https://${ALB_DNS}"
)"

# Assert failure if HTTPS responds with unexpected content
[[ "${HTTPS_BODY}" == *"${EXPECTED_CONTENT}"* ]] || \
    error "HTTPS endpoint did not return the expected application content"

# Affirm successful HTTPS response
printf ' HTTPS response:    %s\n' "expected content received"

# End verification message box
printf '%s\n\n' "------------------------------------------------------------"

# Affirm deployment verification completely successful
printf "Deployment verification passed\n\n"
