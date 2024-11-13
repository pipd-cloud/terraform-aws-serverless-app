resource "aws_security_group" "redis" {
  name        = "${var.id}-redis-cache-sg"
  description = "Security group associated with the Redis cache."
  vpc_id      = data.aws_vpc.vpc.id
  tags = merge({
    Name = "${var.id}-redis-cache-sg"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "redis_inbound" {
  for_each                     = data.aws_security_group.inbound
  description                  = "Allows traffic from ${each.key}."
  security_group_id            = aws_security_group.redis.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = each.value.id
  tags = merge({
    Name = "${var.id}-redis-cache-sg-inbound-${each.key}"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "redis_cache_outbound" {
  description       = "Allows all outbound traffic."
  security_group_id = aws_security_group.redis.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-redis-cache-sg-outbound"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_elasticache_serverless_cache" "redis" {
  engine             = "redis"
  name               = "${var.id}-redis-cache"
  description        = "Redis cache associated with the ${var.id} deployment."
  subnet_ids         = keys(data.aws_subnet.vpc_subnets)
  security_group_ids = [aws_security_group.redis.id]
  tags = merge({
    Name = "${var.id}-redis-cache"
    TFID = var.id
  }, var.aws_tags)
  cache_usage_limits {
    data_storage {
      minimum = var.config.data_storage.min
      maximum = var.config.data_storage.max
      unit    = "GB"
    }
    ecpu_per_second {
      minimum = var.config.ecpu.min
      maximum = var.config.ecpu.max
    }
  }
  timeouts {
    create = var.config.ttl.create
    update = var.config.ttl.update
    delete = var.config.ttl.delete
  }
}
