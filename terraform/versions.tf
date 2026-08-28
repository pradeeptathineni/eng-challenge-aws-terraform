terraform {
  # Keep local development and CI on the same stable Terraform minor release
  required_version = "~> 1.15.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.60.0"
    }
  }
}
