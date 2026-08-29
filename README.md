# AWS Terraform Engineering Challenge

## Description

A simple AWS infrastructure challenge built with Terraform and developed step by step with CI/CD from the start. Github and this README will display my incremental process and decisions in evolving the architecture to support this simple AWS infrastructure. The goal is to meet the required architecture cleanly with CI/CD from the start and with extensibility in mind, while keeping the code, automation, and documentation easy to understand.

---

## AWS Architecture

The completed infrastructure will include (see DevOps Challenge PDF for reference):

- **VPC**
  - CIDR `10.0.0.0/16`

- **Subnets**
  - two public subnets in different availability zones
  - two private subnets in different availability zones

- **Application Load Balancer**
  - internet-facing
  - deployed across the public subnets
  - accepts HTTP on port `80`
  - accepts HTTPS on port `443`
  - terminates HTTPS using a self-signed certificate
  - forwards application traffic to the EC2 instance

- **EC2**
  - one instance in a private subnet
  - runs a simple web server
  - receives application traffic from the load balancer

- **Security groups**
  - ALB allows inbound HTTP and HTTPS
  - EC2 allows application traffic from the ALB security group
  - EC2 allows SSH on port `22` from the VPC CIDR

- **Terraform outputs**
  - ALB DNS name
  - EC2 private IP address

---

## Execution

### Requirements

- [Git](https://git-scm.com/install/)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
- [Terraform 1.16.0](https://developer.hashicorp.com/terraform/install)
- Bash ~ from [Git Bash](https://git-scm.com/install/windows) for Windows
- GNU Make ~ from [Chocolatey](https://community.chocolatey.org/packages/make) for Windows

### Commands

- `make help` - Show available commands
- `make tools` - Check if local tools are installed and their versions
- `make version` - Show the active Terraform version
- `make login` - Log into AWS and verify the active identity
- `make auth` - Verify AWS credentials and show the active AWS account
- `make shell-validate` - Check Bash helper scripts for syntax errors
- `make fmt` - Format all Terraform configuration
- `make fmt-check` - Check Terraform formatting without changing files
- `make init` - Initialize Terraform for local development
- `make init-ci` - Initialize Terraform for CI without backend access
- `make validate` - Initialize and validate Terraform configuration
- `make validate-ci` - Initialize and validate Terraform configuration in CI
- `make plan` - Check AWS identity and create a saved Terraform plan
- `make apply` - Check AWS identity and apply the saved Terraform plan
- `make destroy` - Check AWS identity and destroy managed infrastructure
- `make output` - Show Terraform outputs from the current state
- `make clean` - Remove generated Terraform working files without deleting state

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
