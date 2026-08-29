# security.tf - Create security groups and traffic rules for web resources

# References:
# Terraform AWS provider security group
# Terraform AWS provider security group ingress rule
# Terraform AWS provider security group egress rule

resource "aws_security_group" "alb" {
  name        = "${var.resource_prefix}-sg-alb"
  description = "Security group for the application load balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.resource_prefix}-sg-alb"
  }
}

resource "aws_security_group" "ec2" {
  name        = "${var.resource_prefix}-sg-ec2"
  description = "Security group for the private EC2 web server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.resource_prefix}-sg-ec2"
  }
}

# Allow public HTTP traffic to the ALB
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80

  description = "Allow HTTP from the internet"
}

# Allow public HTTPS traffic to the ALB
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443

  description = "Allow HTTPS from the internet"
}

# Allow the ALB to send web traffic to EC2
resource "aws_vpc_security_group_egress_rule" "alb_to_ec2" {
  security_group_id = aws_security_group.alb.id

  referenced_security_group_id = aws_security_group.ec2.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80

  description = "Allow HTTP to the EC2 web server"
}

# Allow web traffic only from the ALB
resource "aws_vpc_security_group_ingress_rule" "ec2_from_alb" {
  security_group_id = aws_security_group.ec2.id

  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80

  description = "Allow HTTP from the ALB"
}

# Allow SSH from inside the VPC as required by the challenge
resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = var.vpc_cidr
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22

  description = "Allow SSH from the VPC"
}

# Allow outbound traffic from EC2 for workload dependencies
resource "aws_vpc_security_group_egress_rule" "ec2_outbound" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound IPv4 traffic"
}
