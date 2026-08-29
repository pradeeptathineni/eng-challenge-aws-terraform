# main.tf - Network resources

# References:
# Terraform AWS provider AZs data source
# Terraform AWS provider VPC resource
# Terraform AWS provider subnet resource

# Find the standard AZs available to the target AWS account
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  # Use one AZ for each public/private subnet
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    length(var.public_subnet_cidrs)
  )

  # Pair each public subnet CIDR with an AZ
  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs :
    "public-${idx + 1}" => {
      cidr_block        = cidr
      availability_zone = local.availability_zones[idx]
    }
  }

  # Pair each private subnet CIDR with the same AZs
  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs :
    "private-${idx + 1}" => {
      cidr_block        = cidr
      availability_zone = local.availability_zones[idx]
    }
  }
}

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

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.project_name}-subnet-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "${var.project_name}-subnet-${each.key}"
    Tier = "private"
  }
}
