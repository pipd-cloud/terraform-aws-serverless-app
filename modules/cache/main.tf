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
  count                        = length(data.aws_security_group.inbound)
  description                  = "Allows traffic from ${data.aws_security_group.inbound[count.index].name}."
  security_group_id            = aws_security_group.redis.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = data.aws_security_group.inbound[count.index].id
  tags = merge({
    Name = "${var.id}-redis-cache-sg-inbound-${data.aws_security_group.inbound[count.index].name}"
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
  count              = var.serverless ? 1 : 0
  engine             = "redis"
  name               = "${var.id}-redis-cache"
  description        = "Redis cache associated with the ${var.id} deployment."
  subnet_ids         = data.aws_subnet.vpc_subnets[*].id
  security_group_ids = [aws_security_group.redis.id]
  tags = merge({
    Name = "${var.id}-redis-cache"
    TFID = var.id
  }, var.aws_tags)
  cache_usage_limits {
    data_storage {
      minimum = var.serverless_config.data_storage.min
      maximum = var.serverless_config.data_storage.max
      unit    = "GB"
    }
    ecpu_per_second {
      minimum = var.serverless_config.ecpu.min
      maximum = var.serverless_config.ecpu.max
    }
  }
  timeouts {
    create = var.serverless_config.ttl.create
    update = var.serverless_config.ttl.update
    delete = var.serverless_config.ttl.delete
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  count      = var.serverless ? 0 : 1
  name       = "${var.id}-redis-cache-subnet-group"
  subnet_ids = data.aws_subnet.vpc_subnets[*].id
  tags = merge({
    Name = "${var.id}-redis-cache-subnet-group"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_elasticache_parameter_group" "redis" {
  count       = var.serverless ? 0 : 1
  name        = "${var.id}-redis-cache-parameter-group"
  family      = var.config.parameter_group_family # default.redis7
  description = "Parameter group for the Redis cache associated with the ${var.id} deployment."
  dynamic "parameter" {
    for_each = var.config.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
  tags = merge({
    Name = "${var.id}-redis-cache-parameter-group"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_elasticache_cluster" "redis" {
  count                      = var.serverless ? 0 : 1
  cluster_id                 = "${var.id}-redis-cache"
  auto_minor_version_upgrade = var.config.auto_minor_version_upgrade
  engine                     = "redis"
  node_type                  = var.config.node_type # cache.t3.medium
  transit_encryption_enabled = var.config.transit_encryption_enabled
  num_cache_nodes            = var.config.num_cache_nodes # 1
  apply_immediately          = var.config.apply_immediately
  security_group_ids         = [aws_security_group.redis.id]
  engine_version             = var.config.engine_version
  port                       = var.config.port
  subnet_group_name          = aws_elasticache_subnet_group.redis[0].name
  parameter_group_name       = aws_elasticache_parameter_group.redis[0].name
  tags = merge({
    Name = "${var.id}-redis-cache"
    TFID = var.id
  }, var.aws_tags)
}
