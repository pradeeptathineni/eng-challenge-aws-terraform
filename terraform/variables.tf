# variables.tf - Settings that can change between deployments
# Variables set here are those that the deployer would reasonably choose to configure

# References:
# Terraform variables

variable "aws_region" {
  description = "AWS region used to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type used by the web server"
  type        = string
  default     = "t3.micro"
}
