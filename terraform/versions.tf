# versions.tf - Define required Terraform and provider versions
# Keeps local development and CI on compatible tool versions

# References:
# Terraform version constraints
# Terraform provider requirements

terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.60.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.3.0"
    }
  }
}
