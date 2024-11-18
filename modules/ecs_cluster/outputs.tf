output "task_execution_role" {
  description = "The task execution role."
  value       = aws_iam_role.task_execution_role
}

output "cluster" {
  description = "The ECS cluster."
  value       = aws_ecs_cluster.ecs_cluster
}

output "cluster_sg" {
  description = "The cluster SG."
  value       = aws_security_group.cluster_sg
}

