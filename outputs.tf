output "aurora_cluster" {
  description = "The RDS Aurora database."
  value       = module.database.aurora_cluster
}

output "redis_cluster" {
  description = "The Elasticache Redis cache."
  value       = module.cache.redis_cluster
}

output "ecr_task_repo" {
  description = "The ECR repository for tasks."
  value       = module.ecr_repos.task_repo
}

output "ecr_buildcache_repo" {
  description = "The ECR repository for caching."
  value       = module.ecr_repos.buildcache_repo
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
