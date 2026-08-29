# AWS Architecture

This document serves to detail all AWS resources that are defined by and deployable from this project's Terraform infrastructure as code.

> All resources are named using the `<prefix>`, defined by `resource_prefix` in [terraform/locals.tf](../terraform/locals.tf).

---

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
