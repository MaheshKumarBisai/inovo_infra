variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (ALB only)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs (EC2 + RDS)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "inventory"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "inventory"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "S3 bucket name for avatars (must be globally unique)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS listener (leave empty to run HTTP on port 80)"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "Amazon Linux 2023 AMI ID (leave empty to auto-lookup latest)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "EC2 key pair name (optional, for SSM Session Manager instead of SSH)"
  type        = string
  default     = ""
}
