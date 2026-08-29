# outputs.tf - Expose network resource values used by other modules

# References
# Terraform output values

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value = [
    for key in sort(keys(aws_subnet.public)) :
    aws_subnet.public[key].id
  ]
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value = [
    for key in sort(keys(aws_subnet.private)) :
    aws_subnet.private[key].id
  ]
}
