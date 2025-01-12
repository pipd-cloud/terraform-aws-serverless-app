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

output "alb" {
  description = "The load balancer associated with the ECS cluster."
  value       = aws_lb.alb
}

output "alb_https_listener" {
  description = "The cluster load balancer listener for HTTPS."
  value       = var.load_balancer.domain != null ? aws_lb_listener.https[0] : null
}

output "alb_http_listener" {
  description = "The cluster load balancer listener for HTTP."
  value       = var.load_balancer.domain != null ? aws_lb_listener.http[0] : aws_lb_listener.http_fwd[0]
}
