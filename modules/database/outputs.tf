output "aurora_cluster" {
  description = "The RDS Aurora cluster."
  value       = aws_rds_cluster.cluster
}
