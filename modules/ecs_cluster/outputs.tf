output "task_execution_role" {
  description = "The task execution role."
  value       = aws_iam_role.task_execution_role
}

output "cluster" {
  description = "The ECS cluster."
  value       = aws_ecs_cluster.cluster
}

output "cluster_sg" {
  description = "The cluster SG."
  value       = aws_security_group.cluster_sg
}

output "cluster_secrets" {
  description = "The cluster secrets."
  value       = aws_secretsmanager_secret.cluster_secrets
}
