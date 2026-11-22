variable "repository_names" {
  description = "List of ECR repository names"
  type        = list(string)
  default     = ["inovo-backend", "inovo-frontend", "inovo-gateway"]
}

resource "aws_ecr_repository" "repos" {
  for_each             = toset(var.repository_names)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = each.value
  }
}

resource "aws_ecr_lifecycle_policy" "cleanup" {
  for_each   = aws_ecr_repository.repos
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain only the last 15 images to optimize storage costs"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 15
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "repository_urls" {
  description = "Map of ECR repository names to repository URLs"
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}
