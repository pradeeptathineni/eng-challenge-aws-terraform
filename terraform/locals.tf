# locals.tf - Shared values used throughout the Terraform project
# Keeps project naming tags and network settings in one place


# References:
# Terraform local values

locals {
  # Keep resource names tied to the repo name
  project_name = "eng-challenge-aws-terraform"

  # VPC address range
  vpc_cidr = "10.0.0.0/16"

  # Public subnets in the lower address ranges
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  # Private subnets separate and easily identifiable
  private_subnet_cidrs = [
    "10.0.30.0/24",
    "10.0.40.0/24"
  ]

  # Apply default tags to supported AWS resources
  common_tags = {
    Project   = local.project_name
    ManagedBy = "Terraform"
  }
}
