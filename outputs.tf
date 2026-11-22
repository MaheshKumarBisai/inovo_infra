output "alb_dns_name" {
  description = "ALB DNS name (point your domain here)"
  value       = module.alb.alb_dns_name
}

output "backend_private_ip" {
  description = "Backend EC2 private IP"
  value       = module.ec2_backend.private_ip
}

output "gateway_private_ip" {
  description = "Gateway EC2 private IP"
  value       = module.ec2_gateway.private_ip
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.rds_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket for avatar storage"
  value       = module.s3.bucket_name
}

output "iam_instance_profile_arn" {
  description = "EC2 IAM instance profile ARN (for S3 access)"
  value       = aws_iam_instance_profile.ec2_s3.arn
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for Docker image pushes"
  value       = module.ecr.repository_urls
}
