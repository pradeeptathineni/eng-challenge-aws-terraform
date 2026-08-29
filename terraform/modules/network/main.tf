# main.tf - Network resources

# References:
# Terraform AWS provider VPC resource

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # Enable DNS resolution inside the VPC
  enable_dns_support = true

  # Enable DNS hostnames for resources inside the VPC
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
