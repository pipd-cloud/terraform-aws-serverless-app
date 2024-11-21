output "alb" {
  value = { for k, v in module.ecs_svc : k => v.alb }
}

output "load_balancers" {
  value = { for k, v in module.ecs_svc : k => v.alb }
}

output "aurora_cluster" {
  description = "The RDS Aurora database."
  value       = module.database.aurora_cluster
}

output "redis_cluster" {
  description = "The Elasticache Redis cache."
  value       = module.cache.redis_cluster
}
