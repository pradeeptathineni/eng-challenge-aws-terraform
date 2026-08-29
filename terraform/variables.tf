# variables.tf - Settings that can change between deployments

# References:
# Terraform variables

variable "aws_region" {
  description = "AWS region used to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}
