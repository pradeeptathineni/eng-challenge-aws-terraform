# stack.tfvars - Main infrastructure deployment configuration

# WARNING:
# This file is intentionally committed to version control
# Do not store credentials secrets or other sensitive values here

vpc_cidr = "10.0.0.0/16"

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
]

private_subnet_cidrs = [
  "10.0.30.0/24",
  "10.0.40.0/24",
]

web_instance_type = "t3.micro"
