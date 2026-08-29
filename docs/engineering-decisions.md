# Engineering Decisions

This document serves to tell this project's engineering story chronologically and cohesively; a lightweight ADR log.

---

1. **Initial thoughts**
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

1. **`make` as the command interface**
   - Common Terraform and helper operations use short Make commands.
   - Local development and CI can use the same commands where practical.
   - Many orchestration models follow the convention of using a central Makefile to define well-named commands that execute scripts and workflows.
   - The source GitHub repo for Terraform itself does this very same thing.
   - Reference: [github.com/hashicorp/terraform Makefile](https://github.com/hashicorp/terraform/blob/main/Makefile)

1. **CI/CD from the start**
   - CI was configured before AWS resources so every infrastructure change can be checked as the project grows.

1. **GitHub Actions over CircleCI**
   - CircleCI was initially considered and configured.
     - Reference: [Deploy infrastructure with Terraform and CircleCI](https://developer.hashicorp.com/terraform/tutorials/automation/circle-ci)
   - GitHub Actions was chosen and configured in place of CircleCI.
     - CircleCI is more optimizable for performant pipelines.
     - Our CI/CD needs are not as intense for this use case.
     - GitHub Actions suffices well with its simple setup and tight integration to GitHub version control and ecosystem.
     - Reference: [Automate Terraform with GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
   - Reference: [CircleCI vs GitHub Actions](https://devops-daily.com/comparisons/circleci-vs-github-actions)

1. **Saved Terraform plans**
   - Typically when using Terraform in automation or collaboration, we want to have a saved plan, with which we can review and thereafter apply
     - `make plan` saves the plan.
     - `make apply` uses that saved plan instead of creating a new one.
   - Reference: [Running Terraform in automation](https://developer.hashicorp.com/terraform/tutorials/automation/automate-terraform)

1. **Bash for small helper scripts**
   - Bash is used for simple command-line checks that work directly with Terraform and the AWS CLI.
   - Allow for useful wrapping of extended functionality for improved granularity and visibility.
   - Again, this is a widely used convention, also used directly inside the original Terraform GitHub repo.
   - Reference: [github.com/hashicorp/terraform scripts](https://github.com/hashicorp/terraform/tree/main/scripts)

1. **AWS identity guardrails with aws-context.sh script**
   - A read-only script for visibility to ensure operations are being done in the right account by the right person.
   - AWS STS checks the credentials before plan, apply, and destroy operations.
   - The active account and principal are shown before Terraform can affect AWS.
   - An expected account ID can optionally stop commands from running against the wrong account.

1. **No AWS access from CI in the beginning**
   - The preliminary GitHub Actions workflow currently performs static checks only.
   - AWS credentials are not stored or used by the CI workflow (yet).

1. **AWS login with aws-login.sh script**
   - Helps to log into AWS either through modern aws login or an already-configured SSO profile.

1. **Commenting and formatting is standardized across all code**
   - Increases clarity and visibility of semantics and decisions.
   - Added a .editorconfig file to clearly set some formatting standards for this repo.
   - Reference: [Terraform style guide](https://developer.hashicorp.com/terraform/language/style)

1. **Not addressing dev/staging/prod environments without a true need**
   - The challenge requires one deployment.
   - Separate dev and prod configurations would add complexity without solving a current problem.
   - Multiple environments can be added later without redesigning the Terraform modules.

1. **Terraform locals for shared project values**
   - Terraform locals hold values reused throughout the project.
   - The project name, network ranges, availability zone count, and common tags are kept together.
   - Later modules can use the same values without repeating them.
   - Network definitions close together like this gives easy visibility.

1. **Simple naming and tagging conventions**
   - AWS resource names will use the project name followed by their purpose.
     - `eng-challenge-aws-terraform-vpc`
     - `eng-challenge-aws-terraform-alb`
   - Resource names should stay obvious; no unnecessary abbreviations.
   - Supported AWS resources automatically get default tags through the AWS provider resource.
     - `Project` = `eng-challenge-aws-terraform`
     - `ManagedBy` = `Terraform`
   - Resource-specific `Name` tags will be added where resources are created.

1. **Keep the root README lightweight**
   - Serve extra documentation under /docs folder, with reference to them in the root README if needed.
   - Easier on the eyes and soul.
   - Keeps the root README focused on project description, requirements, and running.

1. **Ensure complete end-to-end operation clarity**
   - A user should have no questions between the very first and very last steps of execution.
   - User responsibilities like installing necessary tools and properly configuring their AWS CLI profiles should be very clear.
   - User is also aware of the responsibility to explicitly set their AWS_PROFILE, instead of the helper scripts quietly defaulting to "default" which is not the best.
