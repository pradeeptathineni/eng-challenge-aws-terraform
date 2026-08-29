# AWS Terraform Engineering Challenge

## Description

A simple AWS infrastructure challenge built with Terraform and developed step by step with CI/CD from the start. Github and this README will display my incremental process and decisions in evolving the architecture to support this simple AWS infrastructure. The goal is to meet the required architecture cleanly with CI/CD from the start and with extensibility in mind, while keeping the code, automation, and documentation easy to understand.

---

## AWS Architecture

> All resources are named using the `<prefix>`, defined by `resource_prefix` in [terraform/locals.tf](terraform/locals.tf).

- **VPC**
  - `<prefix>-vpc` &mdash; `10.0.0.0/16`

- **Subnets**
  - Two public subnets in different availability zones
    - `<prefix>-subnet-public-1` &mdash; `10.0.1.0/24`
    - `<prefix>-subnet-public-2` &mdash; `10.0.2.0/24`
  - Two private subnets in different availability zones
    - `<prefix>-subnet-private-1` &mdash; `10.0.30.0/24`
    - `<prefix>-subnet-private-2` &mdash; `10.0.40.0/24`

- **Application Load Balancer**
  - Internet-facing
  - Deployed across the public subnets
  - Accepts HTTP on port `80`
  - Accepts HTTPS on port `443`
  - Terminates HTTPS using a self-signed certificate
  - Forwards application traffic to the EC2 instance

- **EC2**
  - One instance in a private subnet
  - Runs a simple web server
  - Receives application traffic from the load balancer

- **Security groups**
  - ALB allows inbound HTTP and HTTPS
  - EC2 allows application traffic from the ALB security group
  - EC2 allows SSH on port `22` from the VPC CIDR

- **Terraform outputs**
  - ALB DNS name
  - EC2 private IP address

> See DevOps Challenge PDF for original reference.

---

## Execution

### Requirements

- [Git](https://git-scm.com/install/)
- [AWS CLI `v2`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
- [Terraform `1.16.0`](https://developer.hashicorp.com/terraform/install)
- Bash ~ from [Git Bash](https://git-scm.com/install/windows) for Windows
- GNU Make ~ from [Chocolatey](https://community.chocolatey.org/packages/make) for Windows

### Commands

- `make help` &mdash; Show available commands
- `make tools` &mdash; Check if local tools are installed and their versions
- `make version` &mdash; Show the active Terraform version
- `make login` &mdash; Log into AWS and verify the active identity
- `make auth` &mdash; Verify AWS credentials and show the active AWS account
- `make shell-validate` &mdash; Check Bash helper scripts for syntax errors
- `make fmt` &mdash; Format all Terraform configuration
- `make fmt-check` &mdash; Check Terraform formatting without changing files
- `make init` &mdash; Initialize Terraform for local development
- `make init-ci` &mdash; Initialize Terraform for CI without backend access
- `make validate` &mdash; Initialize and validate Terraform configuration
- `make validate-ci` &mdash; Initialize and validate Terraform configuration in CI
- `make plan` &mdash; Check AWS identity and create a saved Terraform plan
- `make apply` &mdash; Check AWS identity and apply the saved Terraform plan
- `make destroy` &mdash; Check AWS identity and destroy managed infrastructure
- `make output` &mdash; Show Terraform outputs from the current state
- `make state-list` &mdash; List resources currently tracked by Terraform state
- `make state-show` &mdash; Show one resource from Terraform state using `RESOURCE=<address>`
- `make clean` &mdash; Remove generated Terraform working files without deleting state

### Running

1. Configure your AWS CLI with the proper credentials if you haven't already.

   ```bash
   # IAM Identity Center / SSO
   aws configure sso --profile <aws-profile>

   # AWS local development login
   aws configure set region <aws-region> --profile <aws-profile>

   # Long-lived IAM access keys if required
   aws configure --profile <aws-profile>
   ```

1. Set AWS_PROFILE to the profile configured to authenticate you to the correct target AWS account.

   ```bash
   export AWS_PROFILE=<aws-profile>

   # sanity check
   echo "$AWS_PROFILE"
   ```

1. Log into AWS and authenticate its authority.

   ```bash
   make login
   make auth

   # sanity check
   aws s3 ls
   ```

1. Plan and deploy the Terraform infrastructure.

   ```bash
   make plan
   make apply
   ```

1. Tear down the deployment when finished.

   ```bash
   make destroy
   ```

### CI

GitHub Actions runs automatically on pushes and pull requests and currently checks:

- Terraform version
- Bash syntax
- Terraform formatting
- Terraform initialization without backend access
- Terraform configuration validation

GitHub Actions uses the same Make commands used locally.

---

## Engineering Decisions

See [docs/engineering-decisions.md](docs/engineering-decisions.md)

---

## References

See [docs/references.md](docs/references.md)
