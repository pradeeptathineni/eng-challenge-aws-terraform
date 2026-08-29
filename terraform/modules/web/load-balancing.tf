# load-balancing.tf - Create the application load balancing layer

# References
# Terraform AWS provider load balancer
# Terraform AWS provider target group
# Terraform AWS provider target group attachment
# Terraform AWS provider load balancer listener

resource "aws_lb" "web" {
  name               = "${var.resource_prefix}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb.id]
  subnets         = var.public_subnet_ids

  tags = {
    Name = "${var.resource_prefix}-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name        = "${var.resource_prefix}-tg-web"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    enabled  = true
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
  }

  tags = {
    Name = "${var.resource_prefix}-tg-web"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
