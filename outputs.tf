output "load_balancers" {
  value = [for i in range(length(module.ecs_svc)) : module.ecs_svc[i].alb]
}

output "aurora_cluster" {
  description = "The RDS Aurora database."
  value       = module.database.aurora_cluster
}

output "redis_cluster" {
  description = "The Elasticache Redis cache."
  value       = module.cache.redis_cluster
}
