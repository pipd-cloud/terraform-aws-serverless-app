# Current Account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnet" "vpc_subnets" {
  count = length(var.vpc_subnet_ids)
  id    = var.vpc_subnet_ids[count.index]
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}


data "aws_security_group" "inbound" {
  count = length(var.security_groups)
  id    = var.security_groups[count.index]
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

# RDS
## Source snapshot (Restore from snapshot)
data "aws_db_cluster_snapshot" "source" {
  count                          = var.cluster_snapshot != null ? 1 : 0
  db_cluster_snapshot_identifier = var.cluster_snapshot
}

data "aws_db_snapshot" "source" {
  count                  = var.instance_snapshot != null ? 1 : 0
  db_snapshot_identifier = var.instance_snapshot
}

locals {
}

## RDS Proxy
data "aws_iam_policy_document" "proxy_role_trust_policy" {
  count = var.proxy ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "proxy_policy" {
  count = var.proxy ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_rds_cluster.cluster.master_user_secret[0].secret_arn]
  }
  statement {
    effect  = "Allow"
    actions = ["kms:Decrypt"]
    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/secretsmanager"
    ]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values = [
        "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "monitoring_trust_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "monitoring" {
  name = "RDSEnhancedMonitoringRole"
}
