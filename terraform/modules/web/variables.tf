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

variable "private_subnet_id" {
  description = "ID of the private subnet used by the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type used by the web server"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets used by the load balancer"
  type        = list(string)
}
