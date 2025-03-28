output "aurora_cluster" {
  description = "The RDS Aurora cluster."
  value       = aws_rds_cluster.cluster
}


output "aurora_cluster_instances" {
  description = "The RDS Aurora database instances."
  value       = aws_rds_cluster_instance.instance
}

output "aurora_cluster_instances_public" {
  description = "The RDS Aurora public database instances."
  value       = aws_rds_cluster_instance.instance_public
}

output "aurora_cluster_proxy" {
  description = "The RDS Aurora cluster proxy."
  value       = var.proxy ? aws_db_proxy.proxy[0] : null
}

output "aurora_cluster_sg" {
  description = "The RDS security group."
  value       = aws_security_group.cluster
}

output "aurora_global_cluster" {
  value = var.global_cluster ? aws_rds_global_cluster.cluster[0] : null
}

output "aurora_cluster_proxy_sg" {
  description = "The RDS security group for the cluster proxy."
  value       = var.proxy ? aws_security_group.proxy[0] : null
}
