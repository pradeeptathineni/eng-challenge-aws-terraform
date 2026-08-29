# versions.tf - Define Terraform and provider requirements for state bootstrap

# References
# Terraform version constraints
# Terraform provider requirements

terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.60.0"
    }
  }
}
