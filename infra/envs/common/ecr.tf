resource "aws_ecr_repository" "app" {
  for_each = toset(["movies-py-api", "questions-gen-vue"])

  name = each.value

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Renamed from expire_untagged once the policy grew a second rule.
moved {
  from = aws_ecr_lifecycle_policy.expire_untagged
  to   = aws_ecr_lifecycle_policy.app
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name

  # ECR evaluates rules by ascending rulePriority, and a `tagStatus = "any"`
  # rule must carry the highest priority number, so it runs last.
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.untagged_image_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.max_image_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_image_count
        }
        action = { type = "expire" }
      },
    ]
  })
}
