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

## Installation, Running, and CI

### Requirements

- Terraform `1.16.0`
- AWS CLI v2
- GNU Make
- Git
- Bash

### AWS authentication

- Authenticate through the normal AWS CLI credential chain
- Check the current AWS identity with `make auth`
- Check local tools and AWS authentication with `make doctor`
- Optionally require a specific AWS account with (locally; do not automate and commit AWS account IDs):

```bash
EXPECTED_AWS_ACCOUNT_ID=123456789012 make auth
```

The AWS context helper script shows the active account, principal, user ID, profile when explicitly selected, and configured CLI region.

### Make commands

- `make help` — Show available commands
- `make tools` — Check local tools and AWS authentication
- `make version` — Show the active Terraform version
- `make auth` — Verify AWS credentials and show the active AWS account
- `make shell-validate` — Check Bash helper scripts for syntax errors
- `make fmt` — Format all Terraform configuration
- `make fmt-check` — Check Terraform formatting without changing files
- `make init` — Initialize Terraform for local development
- `make init-ci` — Initialize Terraform for CI without backend access
- `make validate` — Initialize and validate Terraform configuration
- `make validate-ci` — Initialize and validate Terraform configuration in CI
- `make plan` — Check AWS identity and create a saved Terraform plan
- `make apply` — Check AWS identity and apply the saved Terraform plan
- `make output` — Check AWS identity and destroy managed infrastructure
- `make destroy` — Show Terraform outputs from the current state
- `make clean` — Remove generated Terraform working files without deleting state

### CI

GitHub Actions runs automatically on pushes and pull requests and currently checks:

- Terraform version
- Bash syntax
- Terraform formatting
- Terraform initialization without backend access
- Terraform configuration validation

GitHub Actions uses the same Make commands used locally.

---

## Considerations and Decisions

- **Initial thoughts**
    - Simplest solution that would work perfectly fine:
        - `main.tf`, `providers.tf`, `variables.tf`, and `outputs.tf` define the AWS architecture.
        - Manually ensure I'm authenticated to the correct AWS account through the AWS CLI.
        - Locally deploy to the AWS account using the Terraform CLI.
        - Push it all into a GitHub repo.
    - While the architecture is simple, the above solution misses many needs; being a "DevOps" challenge means many more things to me:
        - Enable the architecture with speed, clarity, visibility, safety, repeatability, and extensibility from the very start.
        - **Extensibility from the start** - every engineering decision made is with the aim of enabling the architecture's growth and future development.
        - **CI/CD from the start** - speed up the engineering feedback loop and provide important historical context for every change.
        - **Modular Terraform architecture** - separate architectural responsibilities so infrastructure is easier to understand, develop, test, and extend.
        - **Scripting automation** - separate useful helper logic, handle edge concerns, and provide clear standardized output around CLI-heavy workflows.
        - **Centralized execution** - centralize determinant models for identical executions of repeated workflows.
        - **Incremental development** - respect version control with clear commits showing understandable and traceable functionality evolution.
        - **Architecture decision records** - record the decisions and tradeoffs that influence how the solution evolves.
        - **Reproducibility** - make it possible for another engineer to clone the repository and reach the same infrastructure state using documented commands.
        - **Validation from the start** - continuously check formatting, syntax, configuration, and later security and infrastructure behavior before changes are deployed.
        - **Safe AWS operations** - make the active AWS account and identity visible before Terraform can plan, apply, or destroy infrastructure.
        - **Secure automation** - avoid long-lived cloud credentials in CI and eventually use short-lived AWS authentication through GitHub OIDC.
        - **Shared and protected state** - move Terraform state to a secure S3 backend before CI begins operating against real infrastructure.
        - **Least privilege** - allow only the network access, AWS permissions, and CI permissions that each component actually needs.
        - **Cost awareness** - avoid adding AWS services or architectural complexity without understanding and documenting why they are needed.
        - **Operational verification** - verify that deployed infrastructure actually works instead of treating a successful `terraform apply` as proof that the application works.
        - **Production-minded tradeoffs** - implement the challenge as requested first, then identify gaps such as private EC2 package access and administrative SSH reachability and address them deliberately.
        - **Engineering discipline from the start** - development of a small architecture continuously shows we're solving a real problem rather than unnecessarily creating a large platform.
        - These are the goals I am developing this architecture with.

- **`make` as the command interface**
    - Common Terraform and helper operations use short Make commands.
    - Local development and CI can use the same commands where practical.
    - Many orchestration models follow the convention of using a central Makefile to define well-named commands that execute scripts and workflows.
    - The source GitHub repo for Terraform itself does this very same thing.
    - Reference: [github.com/hashicorp/terraform Makefile](https://github.com/hashicorp/terraform/blob/main/Makefile)

- **CI/CD from the start**
    - CI was configured before AWS resources so every infrastructure change can be checked as the project grows.

- **GitHub Actions over CircleCI**
    - CircleCI was initially considered and configured.
        - Reference: [Deploy infrastructure with Terraform and CircleCI](https://developer.hashicorp.com/terraform/tutorials/automation/circle-ci)
    - GitHub Actions was chosen and configured in place of CircleCI.
        - CircleCI is more optimizable for performant pipelines.
        - Our CI/CD needs are not as intense for this use case.
        - GitHub Actions suffices well with its simple setup and tight integration to GitHub version control and ecosystem.
        - Reference: [Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
    - Reference: [CircleCI vs GitHub Actions](https://devops-daily.com/comparisons/circleci-vs-github-actions)

- **Saved Terraform plans**
    - Typically when using Terraform in automation or collaboration, we want to have a saved plan, with which we can review and thereafter apply
        - `make plan` saves the plan.
        - `make apply` uses that saved plan instead of creating a new one.
    - Reference: [Running Terraform in automation](https://developer.hashicorp.com/terraform/tutorials/automation/automate-terraform)

- **Bash for small helper scripts**
    - Bash is used for simple command-line checks that work directly with Terraform and the AWS CLI.
    - Allow for useful wrapping of extended functionality for improved granularity and visibility.
    - Again, this is a widely used convention, also used directly inside the original Terraform GitHub repo.
    - Reference: [github.com/hashicorp/terraform scripts](https://github.com/hashicorp/terraform/tree/main/scripts)

- **AWS identity guardrails in aws-context.sh script**
    - AWS STS checks the credentials before plan, apply, and destroy operations
    - The active account and principal are shown before Terraform can affect AWS
    - An expected account ID can optionally stop commands from running against the wrong account

- **No AWS access from CI in the beginning**
    - The preliminary GitHub Actions workflow currently performs static checks only.
    - AWS credentials are not stored or used by the CI workflow (yet).

---

## References

### Main

- [AWS CLI](https://docs.aws.amazon.com/cli/)
- [Terraform CLI](https://developer.hashicorp.com/terraform/cli)
- [Terraform AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GNU Make](https://www.gnu.org/software/make/manual/make.html)
- [GNU Bash](https://www.gnu.org/software/bash/manual/bash.html)
- [GitHub Actions](https://docs.github.com/actions)

### Nuances

- [Hashicorp setup-terraform action](https://github.com/hashicorp/setup-terraform)
- [AWS CLI get-caller-identity](https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html)
- [AWS CLI environment variable configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)

### Influences

- [github.com/hashicorp/terraform](https://github.com/hashicorp/terraform/blob/main)
- [Deploy infrastructure with Terraform and CircleCI](https://developer.hashicorp.com/terraform/tutorials/automation/circle-ci)
- [Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [CircleCI vs GitHub Actions](https://devops-daily.com/comparisons/circleci-vs-github-actions)
- [Running Terraform in automation](https://developer.hashicorp.com/terraform/tutorials/automation/automate-terraform)
