output "aurora_cluster" {
  description = "The RDS Aurora cluster."
  value       = aws_rds_cluster.cluster
}

output "aurora_cluster_sg" {
  description = "The RDS security group."
  value       = aws_security_group.cluster
}
