output "repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.minecraft.name
}

output "repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.minecraft.repository_url
}
