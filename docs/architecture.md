# AWS Architecture

This document serves to detail all AWS resources that are defined by and deployable from this project's Terraform infrastructure as code.

All resources are named using the `<prefix>`, defined by `resource_prefix` in [config/project.tfvars](../config/project.tfvars).

---

### Terraform State

- Local state is supported by default
- Optional remote S3 bucket backend — `<prefix>-tfstate-<aws-account-id>`
  - State stored under `<project_name>/terraform.tfstate`
  - Versioning and server-side encryption enabled
  - Public access blocked and object ACLs disabled
  - Native S3 state locking enabled
- The remote backend is created independently under [`bootstrap/`](../bootstrap/)
  - Terraform backend infrastructure must exist before the main stack can use it
  - [`terraform/s3-backend.tf.example`](../terraform/s3-backend.tf.example) defines the optional S3 backend consumed by the main stack
  - The active backend selection is handled through the state workflows
    - Makefile's `state-local` — configure for local backend
    - Makefile's `state-remote` - configure for remote backend
    - The state workflows allow state to migrate between local and S3 storage
  - The bootstrap remote backend configuration keeps its own state locally
  - Only the main infrastructure state is migrated to S3 when it exists

### VPC — `<prefix>-vpc` — `10.0.0.0/16`

### Subnets

- Two public subnets in different availability zones
  - `<prefix>-subnet-public-1` — `10.0.1.0/24`
  - `<prefix>-subnet-public-2` — `10.0.2.0/24`
- Two private subnets in different availability zones
  - `<prefix>-subnet-private-1` — `10.0.30.0/24`
  - `<prefix>-subnet-private-2` — `10.0.40.0/24`

### Application Load Balancer — `<prefix>-alb`

- Internet-facing across both public subnets
- HTTP `80` redirects to HTTPS `443`
- HTTPS `443` terminates TLS using a self-signed certificate
- Forwards application traffic to the EC2 instance

### TLS Certificate — `<prefix>-cert-alb`

- Terraform-generated self-signed certificate imported into AWS Certificate Manager

### Target Group — `<prefix>-tg-web`

- Forwards HTTP `80` to the private EC2 instance
- Health checks `GET /`

### EC2 — `<prefix>-ec2-web`

- Single private instance web-server
- Amazon Linux 2023 AMI
- `t3.micro` by default
- Deployed in a private subnet without a public IP
- Simple HTTP web server on port `80` using python3 http.server package
- User data configures hardcoded web content
- Receives application traffic from the load balancer

### Security groups

- `<prefix>-sg-alb`
  - Inbound HTTP `80` from `0.0.0.0/0`
  - Inbound HTTPS `443` from `0.0.0.0/0`
  - Outbound HTTP `80` to `<prefix>-sg-ec2`
- `<prefix>-sg-ec2`
  - Inbound HTTP `80` from `<prefix>-sg-alb`
  - Inbound SSH `22` from `10.0.0.0/16`
  - Outbound traffic allowed

### Terraform outputs

- `alb_dns_name` — ALB DNS name
- `ec2_private_ip` — EC2 private IP address

> See [docs/DevOpsChallenge.pdf](../docs/DevOpsChallenge.pdf) for original architecture reference.
