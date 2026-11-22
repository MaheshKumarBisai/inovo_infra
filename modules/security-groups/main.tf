variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_security_group_id" {
  description = "ALB security group ID (optional external reference)"
  type        = string
  default     = ""
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "gateway_sg_id" {
  value = aws_security_group.gateway.id
}

output "backend_sg_id" {
  value = aws_security_group.backend.id
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

# -------------------------------------------------------
# ALB Security Group (Public)
# -------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "inovo-alb-sg"
  description = "Allow HTTP and HTTPS traffic to ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet (for HTTPS redirect)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "inovo-alb-sg" }
}

# -------------------------------------------------------
# Gateway EC2 Security Group (Private)
# -------------------------------------------------------
resource "aws_security_group" "gateway" {
  name        = "inovo-gateway-sg"
  description = "Allow HTTP from ALB to gateway"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "inovo-gateway-sg" }
}

# -------------------------------------------------------
# Backend + Frontend EC2 Security Group (Private)
# -------------------------------------------------------
resource "aws_security_group" "backend" {
  name        = "inovo-backend-sg"
  description = "Allow API from gateway and Frontend from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Frontend HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "FastAPI HTTP from gateway"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  ingress {
    description     = "Redis from gateway"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.gateway.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "inovo-backend-sg" }
}

# -------------------------------------------------------
# RDS PostgreSQL Security Group (Private)
# -------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "inovo-rds-sg"
  description = "PostgreSQL from backend only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from backend EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  tags = { Name = "inovo-rds-sg" }
}
