# VPC
resource "aws_security_group" "cluster_sg" {
  name        = "${var.id}-ecs-cluster-sg"
  description = "Internal cluster traffic SG."
  vpc_id      = data.aws_vpc.vpc.id
  tags = merge({
    Name = "${var.id}-ecs-cluster-sg"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "cluster_sg_inbound_self" {
  security_group_id            = aws_security_group.cluster_sg.id
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.cluster_sg.id
  tags = merge({
    Name = "${var.id}-ecs-cluster-sg-inbound-self"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "cluster_sg_inbound" {
  for_each                     = data.aws_security_group.inbound
  description                  = "Allows traffic from ${each.value.name}."
  security_group_id            = aws_security_group.cluster_sg.id
  ip_protocol                  = -1
  referenced_security_group_id = each.value.id
  tags = merge({
    Name = "${var.id}-ecs-cluster-sg-inbound-${each.key}"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "cluster_sg_outbound" {
  security_group_id = aws_security_group.cluster_sg.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-ecs-cluster-sg-outbound"
    TFID = var.id
  }, var.aws_tags)
}

# KMS
## Fargate ephemeral storage
resource "aws_kms_key" "cmk_fargate" {
  description             = "Encryption key for ephemeral storage on Fargate."
  enable_key_rotation     = true
  rotation_period_in_days = 90
  deletion_window_in_days = 30
  tags = merge({
    Name = "${var.id}/fargate"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_kms_key_policy" "cmk_fargate" {
  key_id = aws_kms_key.cmk_fargate.key_id
  policy = data.aws_iam_policy_document.cmk_fargate_policy.json
}

resource "aws_kms_alias" "cmk_fargate_alias" {
  target_key_id = aws_kms_key.cmk_fargate.key_id
  name          = "alias/${var.id}/fargate"
}

# IAM
## Task Execution Role
resource "aws_iam_role" "task_execution_role" {
  name_prefix        = "ECSTaskExecutionRole_"
  description        = "Role that is assumed by the task execution."
  assume_role_policy = data.aws_iam_policy_document.ecs_trust_policy.json
  tags = merge({
    Name = "ECSTaskExecutionRole"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_policy" "task_execution_policy" {
  name_prefix = "ECSTaskExecutionPolicy_"
  description = "Policies that are granted to the task execution."
  policy      = data.aws_iam_policy_document.task_execution_policy.json
  tags = merge({
    Name = "ECSTaskExecutionPolicy"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_role_policy_attachment" "task_execution_managed_policies" {
  for_each   = data.aws_iam_policy.task_execution_managed_policies
  role       = aws_iam_role.task_execution_role.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "task_exeuctor_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_policy.arn
}

# Secrets
resource "aws_secretsmanager_secret" "cluster_secrets" {
  name = "${var.id}-ecs-cluster-secrets"
  tags = merge({
    Name = "${var.id}-ecs-cluster-secrets"
    TFID = var.id
  }, var.aws_tags)
}

# ECS
resource "aws_ecs_cluster" "ecs_cluster" {
  depends_on = [aws_kms_key.cmk_fargate]
  name       = "${var.id}-ecs-cluster"
  tags = merge({
    Name = "${var.id}-ecs-cluster"
    TFID = var.id
  }, var.aws_tags)
  configuration {
    managed_storage_configuration {
      fargate_ephemeral_storage_kms_key_id = aws_kms_key.cmk_fargate.arn
    }
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
