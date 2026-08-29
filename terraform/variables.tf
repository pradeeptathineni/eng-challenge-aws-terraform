# variables.tf - Settings that can change between deployments

# References:
# Terraform variables

variable "project_name" {
  description = "Name used to identify the Terraform project"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix used when naming AWS resources"
  type        = string
}

variable "aws_region" {
  description = "AWS region used to deploy the infrastructure"
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block used by the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks used by the public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "IPv4 CIDR blocks used by the private subnets"
  type        = list(string)
}

variable "web_instance_type" {
  description = "EC2 instance type used by the web server"
  type        = string
}
