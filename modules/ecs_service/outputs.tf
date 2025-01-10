output "secrets" {
  description = "AWS Secrets Manager Secrets for the service."
  value       = aws_secretsmanager_secret.service
}

