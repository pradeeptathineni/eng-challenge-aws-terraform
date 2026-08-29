# main.tf - Create the protected S3 Terraform state backend

# References:
# Terraform AWS provider caller identity
# Terraform AWS provider S3 bucket
# Terraform AWS provider S3 bucket versioning
# Terraform AWS provider S3 bucket encryption
# Terraform AWS provider S3 public access block
# Terraform AWS provider S3 ownership controls

data "aws_caller_identity" "current" {}

locals {
  state_bucket_name = "${var.resource_prefix}-tfstate-${data.aws_caller_identity.current.account_id}"
  state_key         = "${var.project_name}/terraform.tfstate"
}

resource "aws_s3_bucket" "state" {
  bucket = local.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = local.state_bucket_name
    Purpose = "TerraformState"
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
