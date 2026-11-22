variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  description = "Security group for the ALB"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN (optional, leave empty for HTTP on port 80)"
  type        = string
  default     = ""
}

variable "gateway_instance_id" {
  description = "Gateway EC2 instance ID for target group registration"
  type        = string
}

variable "backend_instance_id" {
  description = "Backend + Frontend EC2 instance ID for target group registration"
  type        = string
}

locals {
  # A valid certificate must be provided and must not contain the dummy placeholder
  has_valid_certificate = var.acm_certificate_arn != "" && !can(regex("ACCOUNT_ID|CERTIFICATE_ID", var.acm_certificate_arn))
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "gateway_target_group_arn" {
  value = aws_lb_target_group.gateway.arn
}

output "frontend_target_group_arn" {
  value = aws_lb_target_group.frontend.arn
}

# -------------------------------------------------------
# Application Load Balancer
# -------------------------------------------------------
resource "aws_lb" "main" {
  name               = "inovo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = { Name = "inovo-alb" }
}

# -------------------------------------------------------
# Target Group: Gateway (Port 4000)
# -------------------------------------------------------
resource "aws_lb_target_group" "gateway" {
  name     = "inovo-gateway-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/healthz"
    port                = "4000"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = { Name = "inovo-gateway-tg" }
}

resource "aws_lb_target_group_attachment" "gateway" {
  target_group_arn = aws_lb_target_group.gateway.arn
  target_id        = var.gateway_instance_id
  port             = 4000
}

# -------------------------------------------------------
# Target Group: Frontend Nginx (Port 80)
# -------------------------------------------------------
resource "aws_lb_target_group" "frontend" {
  name     = "inovo-frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = { Name = "inovo-frontend-tg" }
}

resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn = aws_lb_target_group.frontend.arn
  target_id        = var.backend_instance_id
  port             = 80
}

# -------------------------------------------------------
# HTTP Listener (Port 80)
# -------------------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  # If HTTPS certificate is provided, redirect HTTP 80 -> HTTPS 443
  dynamic "default_action" {
    for_each = local.has_valid_certificate ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  # If no HTTPS certificate, forward port 80 directly to Frontend
  dynamic "default_action" {
    for_each = !local.has_valid_certificate ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.frontend.arn
    }
  }
}

# If no HTTPS certificate, route /api/v1/* and /media/* on HTTP to Gateway
resource "aws_lb_listener_rule" "http_api" {
  count        = !local.has_valid_certificate ? 1 : 0
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/*", "/media/*"]
    }
  }
}

# -------------------------------------------------------
# HTTPS Listener (Port 443) - only created when certificate ARN is provided
# -------------------------------------------------------
resource "aws_lb_listener" "https" {
  count             = local.has_valid_certificate ? 1 : 0
  load_balancer_arn = aws_lb.main.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "https_api" {
  count        = local.has_valid_certificate ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/*", "/media/*"]
    }
  }
}
