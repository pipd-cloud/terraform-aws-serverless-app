# VPC
## Security groups
resource "aws_security_group" "cluster" {
  name        = "${var.id}-rds-cluster-sg"
  description = "Security group associated with the DB instances on the RDS cluster."
  vpc_id      = data.aws_vpc.vpc.id
  tags = merge(
    {
      Name = "${var.id}-rds-cluster-sg"
      TFID = var.id
    },
    var.aws_tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "cluster_sg_inbound" {
  count                        = !var.proxy ? length(data.aws_security_group.inbound) : 0
  security_group_id            = aws_security_group.cluster.id
  description                  = "Allows traffic from ${data.aws_security_group.inbound[count.index].name}"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = data.aws_security_group.inbound[count.index].id
  tags = merge({
    Name = "${var.id}-rds-cluster-sg-inbound-${data.aws_security_group.inbound[count.index].name}"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "cluster_outbound" {
  count             = var.proxy ? 0 : 1
  description       = "Allow all outbound traffic."
  security_group_id = aws_security_group.cluster.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-rds-cluster-sg-outbound"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "cluster_inbound_proxy" {
  count                        = var.proxy ? 1 : 0
  description                  = "Allows traffic from the RDS proxy."
  security_group_id            = aws_security_group.cluster.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.proxy[0].id
  tags = merge({
    Name = "${var.id}-rds-cluster-sg-inbound-proxy"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "cluster_outbound_proxy" {
  count                        = var.proxy ? 1 : 0
  description                  = "Allow all outbound traffic via the RDS Proxy."
  security_group_id            = aws_security_group.cluster.id
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.proxy[0].id
  tags = merge({
    Name = "${var.id}-rds-cluster-sg-outbound-proxy"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_security_group" "proxy" {
  count       = var.proxy ? 1 : 0
  name        = "${var.id}-rds-proxy-sg"
  description = "Security group associated with the RDS proxy."
  vpc_id      = data.aws_vpc.vpc.id
  tags = merge({
    Name = "${var.id}-rds-proxy-sg"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "proxy_sg_inbound" {
  count                        = var.proxy ? length(data.aws_security_group.inbound) : 0
  security_group_id            = aws_security_group.proxy[0].id
  description                  = "Allows traffic from ${data.aws_security_group.inbound[count.index].name}."
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = data.aws_security_group.inbound[count.index].id
  tags = merge({
    Name = "${var.id}-rds-proxy-sg-inbound-${data.aws_security_group.inbound[count.index].name}"
    TFID = var.id
  }, var.aws_tags)
}


resource "aws_vpc_security_group_egress_rule" "proxy_outbound" {
  count             = var.proxy ? 1 : 0
  description       = "Allow all outbound traffic."
  security_group_id = aws_security_group.proxy[0].id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-rds-proxy-sg-outbound"
    TFID = var.id
  }, var.aws_tags)
}

## Subnet group
resource "aws_db_subnet_group" "cluster_subnet_group" {
  name       = "${var.id}-db-cluster-subnet-group"
  subnet_ids = keys(data.aws_subnet.vpc_subnets)
  tags = merge({
    Name = "${var.id}-db-cluster-subnet-group"
    TFID = var.id
  }, var.aws_tags)
}

# RDS
## Aurora cluster
resource "random_id" "final_snapshot_id" {
  byte_length = 8
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier   = "${var.id}-rds-cluster"
  engine               = "aurora-postgresql"
  db_subnet_group_name = aws_db_subnet_group.cluster_subnet_group.name
  engine_version = (
    var.source_snapshot != null ?
    data.aws_db_snapshot.source[0].engine_version : var.engine_version
  )
  final_snapshot_identifier   = "${var.id}-rds-cluster-final-${random_id.final_snapshot_id.hex}"
  master_username             = var.source_snapshot == null ? "root" : null
  manage_master_user_password = true
  snapshot_identifier = (
    var.source_snapshot == null ?
    null : data.aws_db_snapshot.source[0].db_snapshot_arn
  )
  allow_major_version_upgrade = true
  storage_encrypted           = true
  copy_tags_to_snapshot       = true
  vpc_security_group_ids      = [aws_security_group.cluster.id]
  tags = merge({
    Name = "${var.id}-rds-cluster"
    TFID = var.id
  }, var.aws_tags)
  serverlessv2_scaling_configuration {
    min_capacity = var.acu_config.min
    max_capacity = var.acu_config.max
  }
  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
}

## DB instances
resource "aws_rds_cluster_instance" "instance" {
  count              = var.instance_count
  identifier         = "${aws_rds_cluster.cluster.id}-${count.index}"
  cluster_identifier = aws_rds_cluster.cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.cluster.engine
  engine_version     = aws_rds_cluster.cluster.engine_version
  tags = merge({
    Name = "${aws_rds_cluster.cluster.id}-${count.index}"
    TFID = var.id
  }, var.aws_tags)
}

## RDS Proxy
resource "aws_iam_role" "proxy_role" {
  count              = var.proxy ? 1 : 0
  name               = "${var.id}-rds-proxy-role"
  description        = "Role that is assumed by RDS proxy to decrypt the DB secret."
  assume_role_policy = data.aws_iam_policy_document.proxy_role_trust_policy[0].json
  tags = merge({
    Name = "${var.id}-rds-proxy-role"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_policy" "proxy_policy" {
  count  = var.proxy ? 1 : 0
  name   = "${var.id}-rds-proxy-policy"
  policy = data.aws_iam_policy_document.proxy_policy[0].json
  tags = merge({
    Name = "${var.id}-rds-proxy-policy"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_role_policy_attachment" "proxy_policy_attachment" {
  count      = var.proxy ? 1 : 0
  policy_arn = aws_iam_policy.proxy_policy[0].arn
  role       = aws_iam_role.proxy_role[0].name
}

resource "aws_db_proxy" "proxy" {
  count                  = var.proxy ? 1 : 0
  name                   = "${var.id}-rds-proxy"
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 3600
  vpc_subnet_ids         = keys(data.aws_subnet.vpc_subnets)
  vpc_security_group_ids = [aws_security_group.proxy[0].id]
  role_arn               = aws_iam_role.proxy_role[0].arn
  tags = merge({
    Name = "${var.id}-rds-proxy"
    TFID = var.id
  }, var.aws_tags)
  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    description = "Root credentials for the target database."
    secret_arn  = aws_rds_cluster.cluster.master_user_secret[0].secret_arn
  }
}

resource "aws_db_proxy_default_target_group" "proxy_tg" {
  count         = var.proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.proxy[0].name
  connection_pool_config {
    init_query                   = "SELECT 1;"
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "cluster" {
  count                 = var.proxy ? 1 : 0
  db_cluster_identifier = aws_rds_cluster.cluster.cluster_identifier
  db_proxy_name         = aws_db_proxy.proxy[0].name
  target_group_name     = aws_db_proxy_default_target_group.proxy_tg[0].name
}
