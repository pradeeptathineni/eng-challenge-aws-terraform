# Engineering Decisions

This document serves to tell this project's engineering story chronologically and cohesively; a lightweight ADR log.

The &#11088; symbol represents a responsible architecture addition that is not explicitly part of the original infrastructure criteria (see [docs/DevOpsChallenge.pdf](../docs/DevOpsChallenge.pdf)).

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

1. **Modular Terraform infrastructure definitions**
   - The root Terraform configuration defines how the whole architecture is assembled.
   - AWS resources are grouped into modules by their architectural responsibility.
   - Network infrastructure in a `network` module.
   - Web infrastructure in a `web` module.

1. **Enable VPC DNS support**
   - DNS support and DNS hostnames are enabled explicitly on the VPC.
   - This makes the intended VPC DNS behavior clear instead of depending on provider defaults.
   - DNS will be useful as workloads and network services are added.

1. **Code resources dynamically where feasible**
   - Availability zone names can be hard-coded very simply, but that limits the scope of shareability/reproducability.
   - What if this code, which is public and technically open-source, wants to be easily tested by someone in Europe?
   - Terraform can ask AWS which standard AZs are available in the selected region.
   - The first two available zones are used because the challenge requires two availability zones.
   - This allows the same Terraform to work in another AWS region without changing zone names.
   - Also more interesting/fun.
   - Similarly, we can use for_each to create multiple subnets, shortening written code.

1. **Separate routing from core network resources**
   - VPC and subnet resources remain in `main.tf`.
   - Internet routing is kept in `routing.tf`.
   - This keeps the module easier to read without creating unnecessary child modules.

1. **Hold public subnets accountable as "public"**
   - Naming a subnet with "\*public\*" is not what makes it a "public subnet".
   - A public subnet is a subnet that is associated with a Route Table that has a route to an Internet Gateway (Igw). This route allows access from the Public Internet to the subnet.
   - Reference: [AWS Public and Private Subnets](https://www.learnaws.org/2022/06/22/public-private-subnets)
   - &#11088; In this logic, the architecture must evolve from original specifications to include an Internet Gateway.
   - The route table then sends `0.0.0.0/0` traffic to the Internet Gateway.

1. **Module for web infrastructure separate from network infrastructure**
   - The `network` module owns VPC networking and routing.
   - The `web` module owns security and application infrastructure.
   - The root module/main.tf connects the two using module outputs and inputs.

1. **Limit ALB outbound traffic**
   - The ALB only needs to reach the EC2 web server on HTTP port `80`.
   - &#11088; The ALB outbound rule therefore solely targets the EC2 security group on that port.
   - This follows least privilege.
   - Reference: [AWS ALB security groups](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html)
   - Referencing security groups for network rules also helps avoid hardcoding possibly changing IPs.

1. **Allow EC2 outbound traffic**
   - &#11088; The EC2 security group should permit outbound traffic in consideration of web server workloads.
   - The private subnet still has no internet route though.

1. **Makefile should minimize nesting**
   - "Leaf" targets execute units of work.
   - "Branch" targets are composed of leaves and, infrequently, other branches.
   - Show an obvious separation between primitive/focused/helper commands and actual developer workflows.
   - This makes usage more and extensibility more clear.
   - Our CI configuration also benefits from less complexity.

1. **Keep the baseline private workload self-contained**
   - The EC2 instance runs in a private subnet without a public IP, so I had to consider just how does such a machine get access to download packages from the internet, such as those needed for web-hosting.
   - The instance will use Amazon Linux 2023 AMI, which iss resolved through AWS's public SSM AMI parameter rather than a hard-coded regional AMI ID.
   - The EC2 web server will use AL2023's built-in Python runtime so instance bootstrap does not require internet access or package installation.
   - Reference: [AL2023 on Amazon EC2](https://docs.aws.amazon.com/linux/al2023/ug/ec2.html)
   - This makes NAT (expensive) and administrative SSH reachability (could just use Session Manager) totally separate enhancement considerations, rather than hard requirements of the baseline workload!

1. **Separate load balancing from TLS configuration**
   - &#11088; The internet-facing ALB spans both public subnets and forwards traffic to the private EC2 instance through a dedicated target group.
   - Target health is verified over the same HTTP `80` path used by application traffic.
   - HTTP routing is implemented and verified before adding certificate and HTTPS concerns.

1. **Terminate TLS at the application load balancer**
   - A Terraform-generated self-signed certificate is imported into AWS Certificate Manager.
   - HTTP requests redirect to HTTPS while the ALB forwards decrypted HTTP traffic to the private EC2 target.
   - The certificate matches the generated ALB DNS name and uses a modern AWS TLS security policy.
   - Reference: [AWS ALB security policies](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/describe-ssl-policies.html)
   - Terraform-managed private key material is acceptable for this disposable challenge but would be replaced with managed certificate issuance in production

   ### Stable v1 of complete architecture (local backend) has been realized!

1. **Deployed resources shouldn't just look pretty, they should mean something**
   - A script verify.sh helps the deployer verify that infrastructure semantics are as we would expect.
   - Becomes another useful make workflow command.

1. **Centralize configuration**
   - Shared project settings live in `config/project.tfvars`, while main-stack deployment choices live in `config/stack.tfvars`.
   - Centralized configuration best enables users to configure what they want how they want.
   - It also minimized repeating configuration values between related deployments, such as our main Terraform and the optional remote backend bootstrap Terraform.

1. **Enable options for local and remote Terraform backends**
   - The best practice for any good Terraform architecture is to employ a remote backend, where the state can cozily live in mindful version control.
   - Sometimes we won't want that, so the architecture for the simple project still defaults to a local backend.

   ### Stable v2 of complete architecture (local OR remote backend) has been realized!

1. **Complete end-to-end user control of all architecture**
   - User is not forced to live with a S3 backend if they do so choose to use it but then need to remove it.
   - The assertion for manual deletion made sense for security at first, but it's worth it to cover end-to-end creation and deletion programmatically.
   - bootstrap-destroy completes the total removal.
   - The shell script for backend-destroy.sh overrides the prevent_destroy flag by creating a temporary decommission_override.tf with the flag override which is used in the destroy process.

1. **Complete end-to-end automation of deployments**
   - `local-deploy` and `remote-deploy` compose the same Make workflows available for individual execution rather than duplicating Terraform or AWS logic.
   - aws-profile script automates the user's need to configure and set AWS profile.
   - aws-login script now checks for user already logged in, so login is not repeated when workflows are rerun.
   - AWS profile selection is ephemeral and propagated only through the active deployment workflow.
   - Saved bootstrap and infrastructure plans remain visible and require explicit confirmation before application.
   - State selection is explicit so each complete deployment guarantees the local or remote backend mode named by the workflow.
   - All this just to enable the laziness itch to be as hands off as possible. But isn't that the whole point of devops and automation?

1. **Automate profile configuration**
   - Before I asked of the user to ensure their AWS profile is correctly set up.
   - aws-profile.sh checks, set up, and confirms all that now.
   - One more step towards more freedom.

1. **Robustly check all needed tools**
   - Some tools are version-agnostic, some are version-relevant, and all must be checked properly.
   - For versioned ones, knowing the tool name, needed version, execution command for version, and regex to get the version is useful.
   - Method to compare A.B.C, A.B, or even just major A versions is needed.
   - Checking tools before anything else ensures the user is set for proper deployments every time.

1. **Deduplicated workflow logic and full auto**
   - `ORCHESTRATED=1` prevents repeated authentication, validation, and initialization once those prerequisites are already established.
   - `AUTO=1` supports fully non-interactive runs, while numbered step banners keep longer workflows readable.

1. **Reuse credentials before starting new sessions**
   - Authentication behavior is determined from the selected AWS profile rather than assuming one login method.
   - Existing short-lived credentials are reused when they can still be resolved successfully.
   - IAM Identity Center login is only invoked when reusable SSO credentials are unavailable, avoiding unnecessary browser prompts.
   - Login remains separate from AWS account and principal validation so each concern can fail independently.

   ### Stable v3 of complete architecture (local/remote backend) with complete end-to-end automations has been realized!

1. **Commenting is thorough and standard across all files**
   - Title; still working on it though.

1. **README is clear, structured, accurate, practical, and pretty**
   - As the guidance entrypoint to this project for the user, the README.md should consider all advantages.
   - Take inspiration and conventions from popular repos with nice READMEs.
   - Reference: [awesome-readme GitHub](https://github.com/matiassingers/awesome-readme)

1. **Ensure complete production-worthiness**
   - Python http.server documentation explicitly states not to use for production.
   - Therefore, a small refactor into nginx web server with NAT is necessary.
   - Reference: [python3 http.server](https://docs.python.org/3/library/http.server.html)
   - A truly resilient multi-AZ production design normally uses a NAT gateway in each AZ that has private workloads requiring egress.
     - AWS specifically recommends per-AZ NAT gateways for improved resiliency.
     - Reference: [AWS NAT use cases](https://docs.aws.amazon.com/vpc/latest/userguide/nat-gateway-scenarios.html)
     - I wouldn't treat this architecure as a fully high availability (HA) production application just to host one HTML page.
   - I also won't bother with creating a bastion just to prove SSH semantics.
     - AMI AL2023 comes with SSM agent preinstalled anyway.
     - With NAT added for Nginx/package egress, the instance can also reach the Systems Manager service endpoints through outbound internet.
     - Alternatively, SSM can later be made entirely private using VPC endpoints.
   - ACTUALLY I HAVE THOUGHT ABOUT IT...
     - Regardless of if I made this change, this architecture is not completely production ready, only production minded, due to several other factors that go beyond the challenge architecture.
     - See below.

1. **Understand current limitations and simplifications**
   - The workload uses one EC2 instance, so it is not highly available.
     - The challenge requires only one instance.
     - Auto scaling or multiple targets would add scope without much extra value here.
   - The web server uses Python's built-in `http.server`, which is not intended for production.
     - Nginx or another production server would be more appropriate.
     - That would also require package egress, a NAT path, or a prebuilt image.
   - TLS uses a self-signed certificate.
     - This directly follows the challenge requirement.
     - Production would normally use a trusted ACM certificate and real domain.
   - SSH is allowed from the VPC CIDR because the challenge requires it.
     - No bastion is added because it creates another host, attack surface, and maintenance burden.
     - Production access would more likely use Systems Manager Session Manager.
   - The private instance has no general outbound internet access.
     - That keeps the design simple and avoids NAT cost.
     - Real workloads may need NAT, VPC endpoints, or prebuilt images for updates and dependencies.
   - Remote Terraform state is optional, while bootstrap state stays local.
     - Making the backend manage its own state creates a circular dependency.
     - The small bootstrap state is easier to protect separately.
   - CI performs static validation only.
     - This avoids storing long-lived AWS credentials in GitHub.
     - Remote planning or deployment could later use GitHub Actions OIDC.
   - Observability is intentionally limited.
     - Production would normally add stronger logging, metrics, alerting, dashboards, and runbooks.
   - The design is production-minded, not fully production-ready.
     - Extra resilience and controls should follow real workload needs, not be added only for completeness.
