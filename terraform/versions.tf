# versions.tf - Define required Terraform and provider versions
# Keeps local development and CI on compatible tool versions

# References:
# Terraform version constraints

terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.60.0"
    }
  }
}
