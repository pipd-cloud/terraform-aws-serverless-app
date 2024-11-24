output "load_balancers" {
  description = "Load balancers for the services."
  value       = module.ecs_services[*].alb
}

output "aurora_cluster" {
  description = "The RDS Aurora database."
  value       = module.database.aurora_cluster
}

output "redis_cluster" {
  description = "The Elasticache Redis cache."
  value       = module.cache.redis_cluster
}
