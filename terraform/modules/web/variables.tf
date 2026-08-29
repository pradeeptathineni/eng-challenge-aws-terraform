# variables.tf - Define inputs required by the web module

# References:
# Terraform variables

variable "resource_prefix" {
  description = "Prefix used when naming AWS resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC used by web resources"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block used by the VPC"
  type        = string
}
