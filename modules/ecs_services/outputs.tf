output "secrets" {
  description = "AWS Secrets Manager Secrets for the HTTP service."
  value       = aws_secretsmanager_secret.ecs_svc_secrets
}

output "alb" {
  description = "The ALB of the service if it is a webservice."
  value       = aws_lb.alb
}
