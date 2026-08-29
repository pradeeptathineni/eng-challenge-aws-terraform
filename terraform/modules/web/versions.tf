# versions.tf - Define provider requirements for the web module

# References:
# Terraform provider requirements
# Terraform providers within modules

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.60.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.3.0"
    }
  }
}
