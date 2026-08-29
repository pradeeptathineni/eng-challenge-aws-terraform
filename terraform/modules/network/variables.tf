# variables.tf - Define inputs required by the network module

# References:
# Terraform variables

variable "project_name" {
  description = "Project name used when naming network resources"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block used by the VPC"
  type        = string
}
