output "ecr_repository_urls" {
  description = "Repository name => registry URL. Feeds the chart's image.repository value."
  value       = { for name, repo in aws_ecr_repository.app : name => repo.repository_url }
}
