# outputs.tf - Expose remote state backend information

# References:
# Terraform output values

output "state_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.state.id
}

output "state_key" {
  description = "S3 object key used by the main Terraform state"
  value       = local.state_key
}

output "state_region" {
  description = "AWS region containing the Terraform state bucket"
  value       = var.aws_region
}
