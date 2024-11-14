output "secrets" {
  description = "AWS Secrets Manager Secrets for the HTTP service."
  value       = aws_secretsmanager_secret.http_secrets
}
