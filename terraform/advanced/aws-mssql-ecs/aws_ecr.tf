# ECR Repository for SQL Server export container

resource "aws_ecr_repository" "export" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "export" {
  repository = aws_ecr_repository.export.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus     = "any"
        countType     = "imageCountMoreThan"
        countNumber   = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Output for convenience when pushing images
output "ecr_repository_url" {
  value       = aws_ecr_repository.export.repository_url
  description = "ECR repository URL for docker push"
}
