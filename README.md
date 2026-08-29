# AWS Terraform Engineering Challenge

## Description

A simple AWS infrastructure challenge built with Terraform and developed step by step with CI/CD from the start. Github and this README will display my incremental process and decisions in evolving the architecture to support this simple AWS infrastructure. The goal is to meet the required architecture cleanly with CI/CD from the start and with extensibility in mind, while keeping the code, automation, and documentation easy to understand.

---

## AWS Architecture

> All resources are named using the `<prefix>`, defined by `resource_prefix` in [terraform/locals.tf](terraform/locals.tf).

### VPC

- `<prefix>-vpc` — `10.0.0.0/16`

### Subnets

- Two public subnets in different availability zones
  - `<prefix>-subnet-public-1` — `10.0.1.0/24`
  - `<prefix>-subnet-public-2` — `10.0.2.0/24`
- Two private subnets in different availability zones
  - `<prefix>-subnet-private-1` — `10.0.30.0/24`
  - `<prefix>-subnet-private-2` — `10.0.40.0/24`

### Application Load Balancer

- Internet-facing
- Deployed across the public subnets
- Accepts HTTP on port `80`
- Accepts HTTPS on port `443`
- Terminates HTTPS using a self-signed certificate
- Forwards application traffic to the EC2 instance

### EC2

- One instance in a private subnet
- Runs a simple web server
- Receives application traffic from the load balancer

### Security groups

- `<prefix>-sg-alb`
  - inbound HTTP `80` from `0.0.0.0/0`
  - inbound HTTPS `443` from `0.0.0.0/0`
  - outbound HTTP `80` to `<prefix>-sg-ec2`
- `<prefix>-sg-ec2`
  - inbound HTTP `80` from `<prefix>-sg-alb`
  - inbound SSH `22` from `10.0.0.0/16`
  - outbound traffic allowed

### Terraform outputs

- ALB DNS name
- EC2 private IP address

> See [DevOpsChallenge.pdf](DevOpsChallenge.pdf) for original architecture reference.

---

## Execution

### Requirements

- [Git](https://git-scm.com/install/)
- [AWS CLI `v2`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
- [Terraform `1.16.0`](https://developer.hashicorp.com/terraform/install)
- Bash ~ from [Git Bash](https://git-scm.com/install/windows) for Windows
- GNU Make ~ from [Chocolatey](https://community.chocolatey.org/packages/make) for Windows

### Commands

> The Makefile provides higher-level developer workflows for robust execution and focused helper commands for individual operations.

#### Workflows

- `make login` — Log into AWS and verify the active identity
- `make check` — Run shell syntax, Terraform formatting, and Terraform validation checks
- `make plan` — Run project checks, verify AWS identity, initialize Terraform, and create a saved deployment plan
- `make apply` — Verify AWS identity and apply the previously saved plan
- `make destroy` — Verify AWS identity and destroy the managed infrastructure

#### Helpers

- `make help` — Show available commands
- `make tools` — Check required local tools and show their versions
- `make auth` — Verify AWS credentials and show the active identity
- `make shell-validate` — Check Bash helper scripts for syntax errors
- `make fmt` — Format all Terraform configuration
- `make fmt-check` — Check Terraform formatting without changing files
- `make init` — Initialize Terraform with the configured backend
- `make validate` — Initialize without backend access and validate Terraform
- `make plan-show` — Show the saved Terraform plan
- `make output` — Show Terraform outputs from the current state
- `make state-list` — List resources currently tracked by Terraform state
- `make state-show` — Show one resource from Terraform state using `RESOURCE=<address>`
- `make clean` — Remove generated Terraform working files without deleting state

### Running

0. Configure your AWS CLI with the proper credentials using any of these methods if you haven't already.

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

   # sanity check
   aws s3 ls
   ```

1. Run syntax, formatting, and validation checks on shell and Terraform code.

   ```bash
   make check
   ```

1. Initialize, validate, and plan the Terraform infrastructure.

   ```bash
   make plan
   ```

1. Apply the Terraform infrastructure.

   ```bash
   make apply
   ```

1. Tear down the deployment when finished.

   ```bash
   make destroy
   ```

### CI

> GitHub Actions runs automatically on pushes and pull requests to `main` using the same `make check` workflow available locally.

> Terraform `1.16.0` is installed explicitly in CI to keep automation aligned with local development.

#### Current static checks include:

- Bash helper script syntax
- Terraform formatting
- Terraform initialization without backend access
- Terraform configuration validation

> CI does not currently require AWS credentials or access to deployed infrastructure or Terraform state.

---

## Engineering Decisions

See [docs/engineering-decisions.md](docs/engineering-decisions.md)

---

## References

See [docs/references.md](docs/references.md)
