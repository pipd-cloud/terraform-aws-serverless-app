output "aurora_cluster" {
  description = "The RDS Aurora cluster."
  value       = module.database.aurora_cluster
}

output "aurora_cluster_instances" {
  description = "The RDS Aurora database instances."
  value       = module.database.aurora_cluster_instances
}

output "aurora_cluster_proxy" {
  description = "The RDS Aurora cluster proxy."
  value       = module.database.aurora_cluster_proxy
}

output "aurora_cluster_sg" {
  description = "The RDS Aurora security group."
  value       = module.database.aurora_cluster_sg
}

output "aurora_cluster_proxy_sg" {
  description = "The RDS Aurora security group for the cluster proxy."
  value       = module.database.aurora_cluster_proxy_sg
}

output "aurora_global_cluster" {
  value = module.database.aurora_global_cluster
}

output "redis_cluster" {
  description = "The Elasticache Redis cache."
  value       = module.cache.redis_cluster
}

output "redis_cluster_sg" {
  description = "The Elasticache Redis security group."
  value       = module.cache.redis_cluster_sg
}

output "ecr_repos" {
  description = "The ECR repositories."
  value       = module.ecr_repo
}

output "ecs_cluster" {
  description = "The ECS cluster."
  value       = module.ecs_cluster.cluster
}

output "ecs_cluster_sg" {
  description = "The ECS cluster security group."
  value       = module.ecs_cluster.cluster_sg
}

output "ecs_cluster_secrets" {
  description = "The ECS cluster SecretsManager Secret."
  value       = module.ecs_cluster.cluster_secrets
}

output "ecs_cluster_task_execution_role" {
  description = "The ECS cluster task execution role."
  value       = module.ecs_cluster.task_execution_role
}

output "ecs_cluster_load_balancer" {
  description = "Load balancer for the cluster."
  value       = module.ecs_cluster.alb
}

output "ecs_cluster_https_listener" {
  description = "The HTTPS listener for the cluster load balancer."
  value       = module.ecs_cluster.alb_https_listener
}

output "ecs_cluster_http_listener" {
  description = "The HTTP listener for the cluster load balancer."
  value       = module.ecs_cluster.alb_http_listener
}

output "ecs_cluster_load_balancer_sg" {
  description = "Cluster load balancer security group."
  value       = module.ecs_cluster.alb_sg
}

output "batch_task_role" {
  description = "The IAM role for Batch tasks."
  value       = module.batch.task_role
}

output "batch_compute_environment" {
  description = "The Batch compute environment."
  value       = module.batch.compute_environment
}

output "batch_job_queue" {
  description = "The Batch job queue."
  value       = module.batch.job_queue
}
