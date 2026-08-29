# providers.tf - Configure the AWS provider used by the project

# References:
# Terraform AWS provider

provider "aws" {
  region = var.aws_region

  # Add default tags to supported AWS resources from locals
  default_tags {
    tags = local.common_tags
  }
}
