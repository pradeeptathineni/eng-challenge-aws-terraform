# compute.tf - Create the private EC2 web workload

# References:
# AWS Systems Manager public AMI parameters
# Terraform AWS provider EC2 instance
# Amazon EC2 user data

data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "web" {
  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  subnet_id                   = var.private_subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = false

  user_data                   = file("${path.module}/user-data.sh")
  user_data_replace_on_change = true

  # Require IMDSv2 for instance metadata requests
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Keep the root volume small and encrypted
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.resource_prefix}-ec2-web"
  }
}
