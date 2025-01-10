output "load_balancer" {
  description = "Load balancer for the cluster."
  value       = module.ecs_cluster.alb
}

output "aurora_cluster" {
  description = "The RDS Aurora database."
  value       = module.database.aurora_cluster
}

output "redis_cluster" {
  description = "The Elasticache Redis cache."
  value       = module.cache.redis_cluster
}
