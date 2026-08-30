# AWS Terraform Engineering Challenge

## Description

An AWS infrastructure challenge built with Terraform and developed step by step with CI/CD from the start. Github and this README display the incremental process and decisions in evolving the architecture to support this simple AWS infrastructure. The goal is to meet the required architecture cleanly, with CI/CD and extensibility in mind from the start, while keeping the code, automation, and documentation easy to understand and reproduce.

---

## Architecture

> See [docs/architecture.md](docs/architecture.md) for complete project architecture.

> See [docs/engineering-decisions.md](docs/engineering-decisions.md) for architectural decision process from start to finish.

> See [docs/DevOpsChallenge.pdf](docs/DevOpsChallenge.pdf) for original architecture criteria.

---

## Configuration

Configurable deployment settings are centralized under [`config/`](config/).

- [`config/project.tfvars`](config/project.tfvars) — settings shared by the main stack and optional state bootstrap
  - Project identity
  - Resource naming
  - AWS region
- [`config/stack.tfvars`](config/stack.tfvars) — main infrastructure settings
  - VPC CIDR
  - Subnet CIDRs
  - EC2 web server instance type

---

## Execution

### Requirements

- [Git](https://git-scm.com/install/)
- [AWS CLI `v2`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
- [Terraform `1.16.0`](https://developer.hashicorp.com/terraform/install)
- Bash ~ from [Git Bash](https://git-scm.com/install/windows) for Windows
- GNU Make ~ from [Chocolatey](https://community.chocolatey.org/packages/make) for Windows

### Commands

The Makefile provides higher-level developer workflows for robust execution and focused helper commands for individual operations.

#### Workflows

- `make login` — Log into AWS and verify the active identity
- `make check` — Run all static project checks
- `make plan` — Run checks, verify AWS identity, initialize the selected backend, and create a saved Terraform plan
- `make apply` — Verify AWS identity and apply the saved Terraform plan
- `make verify` — Verify the deployed application end-to-end
- `make destroy` — Verify AWS identity and destroy managed infrastructure

#### State workflows

- `make bootstrap-plan` — Create a saved plan for the optional remote state infrastructure
- `make bootstrap-apply` — Apply the previously saved remote state infrastructure plan
- `make bootstrap-destroy` — Permanently remove remote state infrastructure after verifying the main stack has been destroyed
- `make state-remote` — Enable S3 remote state and migrate existing local state when needed
- `make state-local` — Enable local state and migrate existing remote state when needed

#### Helpers

- `make help` — Show available commands
- `make tools` — Check required local tools and show their versions
- `make auth` — Verify AWS credentials and show the active identity
- `make shell-validate` — Check Bash helper scripts for syntax errors
- `make fmt` — Format all Terraform configuration
- `make fmt-check` — Check Terraform formatting without changing files
- `make init` — Initialize the selected Terraform state backend
- `make validate` — Validate all Terraform configuration without backend access
- `make plan-show` — Show the saved Terraform plan
- `make output` — Show Terraform outputs from the current state
- `make state-list` — List resources currently tracked by Terraform state
- `make state-show` — Show one resource from Terraform state using `RESOURCE=<address>`
- `make clean` — Remove generated Terraform working files without deleting state

### Running

#### 1. Configure AWS access

Configure the AWS CLI using an appropriate authentication method if needed.

```bash
# IAM Identity Center / SSO
aws configure sso --profile <aws-profile>

# AWS local development login
aws configure set region <aws-region> --profile <aws-profile>

# Long-lived IAM access keys if required
aws configure --profile <aws-profile>
```

Select the AWS profile for the deployment:

```bash
export AWS_PROFILE=<aws-profile>

# sanity check
echo "$AWS_PROFILE"
```

Authenticate and verify the active AWS identity:

```bash
make login

# sanity check
aws sts get-caller-identity
```

#### 2. Review deployment configuration

Shared project settings and main-stack infrastructure settings are defined under [`config/`](config/):

```text
config/
    project.tfvars
    stack.tfvars
```

Modify these files before planning if different project naming, AWS region, network ranges, or web EC2 sizing are required.

#### 3. Choose a state backend mode

Local state backend is the default and requires no additional setup (can move on to next step).

To use protected S3 remote state backend instead, first bootstrap the backend into existence:

```bash
make bootstrap-plan
make bootstrap-apply
```

Then enable remote state:

```bash
make state-remote
```

Existing local state is migrated when applicable. A fresh deployment initializes directly against the S3 backend.

To migrate the main stack back to local state:

```bash
make state-local
```

You are able to go vice-versa as needed.

#### 4. Validate and plan

Run the complete static validation workflow:

```bash
make check
```

Create and review a saved Terraform plan:

```bash
make plan
make plan-show
```

#### 5. Deploy

Apply the exact saved plan:

```bash
make apply
```

Inspect the deployed Terraform state and required outputs:

```bash
make output
make state-list
make state-show RESOURCE='<address>'
```

#### 6. Verify

Verify the deployed infrastructure and application end-to-end:

```bash
make verify
```

#### 7. Tear down

_**(a) TYPICAL**_ — Destroy the main infrastructure:

```bash
make destroy

# optional: clean up generated remnants
# excluding state and lock files
make clean
```

_**(b) LAST CASE**_ — Destroy the main infrastructure and the bootstrap S3 backend infrastructure:

```bash
make destroy
make bootstrap-destroy

# optional: clean up everything
# including state and lock files
make deep-clean
```

> **WARNING**: This action is irreversible and removes all retained Terraform state history.

### Continuous Integration

GitHub Actions runs automatically on pushes and pull requests to `main` using the same `make check` workflow available locally.

Terraform `1.16.0` is installed explicitly in CI to keep automation aligned with local development.

#### Current static checks include:

- Bash helper script syntax
- Terraform formatting
- Shared deployment configuration formatting
- Terraform initialization without backend access
- Main stack and bootstrap configuration validation

CI currently requires neither AWS credentials nor access to Terraform state or deployed infrastructure.

Authenticated remote-state planning can be added separately using GitHub Actions OIDC in the future.

---

## References

> See [docs/references.md](docs/references.md) for referenced material.
