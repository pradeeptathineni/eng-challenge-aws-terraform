# versions.tf - Network module provider requirements

# References:
# Terraform provider requirements
# Terraform providers within modules

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.60.0"
    }
  }
}
