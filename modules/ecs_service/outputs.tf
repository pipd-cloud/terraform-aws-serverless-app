output "secrets" {
  description = "AWS Secrets Manager Secrets for the service."
  value       = aws_secretsmanager_secret.service
}

output "alb" {
  description = "The ALB of the service if it is a webservice."
  value       = aws_lb.alb
}
