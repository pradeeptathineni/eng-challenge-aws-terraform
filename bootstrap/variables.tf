# variables.tf - Define inputs required by the state bootstrap

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
  description = "AWS region used for the Terraform state bucket"
  type        = string
}
