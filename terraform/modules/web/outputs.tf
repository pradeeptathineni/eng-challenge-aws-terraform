# outputs.tf - Expose values created by the web module

# References:
# Terraform outputs

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.web.dns_name
}

output "ec2_private_ip" {
  description = "Private IP address of the EC2 web server"
  value       = aws_instance.web.private_ip
}
