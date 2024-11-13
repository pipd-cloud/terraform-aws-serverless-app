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
      data.aws_kms_alias.ecr.target_key_arn,
      data.aws_kms_alias.secretsmanager.target_key_arn,
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

# AWS Managed Keys
data "aws_kms_alias" "ecr" {
  name = "alias/aws/ecr"
}

data "aws_kms_alias" "secretsmanager" {
  name = "alias/aws/secretsmanager"
}

# VPC
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_security_group" "inbound" {
  for_each = toset(var.security_groups)
  id       = each.value
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}
