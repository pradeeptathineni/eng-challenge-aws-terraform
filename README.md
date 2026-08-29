# AWS Terraform Engineering Challenge

## Description

An AWS infrastructure challenge built with Terraform and developed step by step with CI/CD from the start. Github and this README display the incremental process and decisions in evolving the architecture to support this simple AWS infrastructure. The goal is to meet the required architecture cleanly, with CI/CD and extensibility in mind from the start, while keeping the code, automation, and documentation easy to understand and reproduce.

---

## Architecture

> See [docs/architecture.md](docs/architecture.md) for project architecture.

> See [docs/engineering-decisions.md](docs/engineering-decisions.md) for architectural decision process.

> See [DevOpsChallenge.pdf](DevOpsChallenge.pdf) for original architecture criteria.

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

   # sanity checks
   make auth
   aws s3 ls
   ```

1. Run syntax, formatting, and validation checks on shell and Terraform code.

   ```bash
   make check
   ```

1. Initialize, validate, and plan the Terraform infrastructure.

   ```bash
   make plan

   # sanity check
   make plan-show
   ```

1. Apply the Terraform infrastructure.

   ```bash
   make apply

   # sanity checks
   make output
   make state-list
   make state-show RESOURCE=<address>
   ```

1. Tear down the deployment when finished.

   ```bash
   make destroy

   # sanity completion
   make clean
   ```

### Continuous Integration

> GitHub Actions runs automatically on pushes and pull requests to `main` using the same `make check` workflow available locally.

> Terraform `1.16.0` is installed explicitly in CI to keep automation aligned with local development.

#### Current static checks include:

- Bash helper script syntax
- Terraform formatting
- Terraform initialization without backend access
- Terraform configuration validation

> CI does not currently require AWS credentials or access to deployed infrastructure or Terraform state.

---

## References

> See [docs/references.md](docs/references.md) for referenced material.
