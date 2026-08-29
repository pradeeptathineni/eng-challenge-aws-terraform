# locals.tf - Shared values used throughout the Terraform project

# References:
# Terraform local values

locals {
  # Apply default tags to supported AWS resources
  common_tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}
