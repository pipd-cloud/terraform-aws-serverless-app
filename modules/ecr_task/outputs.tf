output "task_repo" {
  description = "The ECR repo used for storing tasks."
  value       = aws_ecr_repository.task
}

output "buildcache_repo" {
  description = "The ECR repo used for the build cache."
  value       = aws_ecr_repository.buildcache
}
