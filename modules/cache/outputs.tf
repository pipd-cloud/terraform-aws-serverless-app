output "redis_cluster" {
  value       = aws_elasticache_serverless_cache.redis
  description = "Serverless Redis cache resource."
}
