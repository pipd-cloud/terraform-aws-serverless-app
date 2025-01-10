# Current Account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# IAM
## Task execution policies
data "aws_iam_policy_document" "ecs_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "task_execution_managed_policies" {
  for_each = toset(["AmazonECSTaskExecutionRolePolicy"])
  name     = each.value
}

data "aws_iam_policy_document" "task_execution_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup"
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.id}-*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/secretsmanager",
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:alias/aws/ecr",
      aws_kms_key.cmk_fargate.arn
    ]
  }
}

# KMS
## Fargate CMK policy
data "aws_iam_policy_document" "cmk_fargate_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["fargate.amazonaws.com"]
    }
    effect    = "Allow"
    actions   = ["kms:GenerateDataKeyWithoutPlaintext"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:ecs:clusterAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:ecs:clusterName"
      values   = ["${var.id}-ecs-cluster"]
    }
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["fargate.amazonaws.com"]
    }
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:ecs:clusterAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:ecs:clusterName"
      values   = ["${var.id}-ecs-cluster"]
    }
    condition {
      test     = "ForAllValues:StringEquals"
      variable = "kms:GrantOperations"
      values   = ["Decrypt"]
    }
  }
}

# VPC
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_security_group" "inbound" {
  count = length(var.security_groups)
  id    = var.security_groups[count.index]
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}
# Load balancer configuration


data "aws_security_group" "internal" {
  count = var.load_balancer != null ? length(var.load_balancer.security_groups) : 0
  id    = var.load_balancer.security_groups[count.index]
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_prefix_list" "internal" {
  count          = var.load_balancer != null ? length(var.load_balancer.prefix_lists) : 0
  prefix_list_id = var.load_balancer.prefix_lists[count.index]
}

