output "redis_cluster" {
  value       = var.serverless ? aws_elasticache_serverless_cache.redis[0] : aws_elasticache_cluster.redis[0]
  description = "Serverless Redis cache resource."
}
