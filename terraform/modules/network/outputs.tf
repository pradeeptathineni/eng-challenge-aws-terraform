# outputs.tf - Expose network resource values used by other modules

# References
# Terraform output values

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}
