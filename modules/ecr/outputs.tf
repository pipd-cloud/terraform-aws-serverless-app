output "repo" {
  description = "The ECR repo used for storing tasks."
  value       = aws_ecr_repository.task
}
