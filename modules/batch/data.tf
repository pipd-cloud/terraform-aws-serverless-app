# Current Account
data "aws_region" "current" {}

# VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet" "private" {
  count = length(var.vpc_private_subnets)
  id    = var.vpc_private_subnets[count.index]
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

data "aws_security_group" "ecs" {
  id = var.cluster_sg
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# IAM
data "aws_iam_policy_document" "batch" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "batch" {
  name = "AWSBatchServiceRole"
}

## Task Execution
data "aws_iam_role" "task_execution" {
  name = var.task_execution_role
}

## Task (Container)
data "aws_iam_policy" "task" {
  for_each = toset(var.managed_policies)
  name     = each.value
}


data "aws_iam_policy_document" "task" {
  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:CreateControlChannel",
    ]
    resources = ["*"]
  }
  dynamic "statement" {
    for_each = {
      for statement in var.policy :
      statement.sid => statement
    }
    content {
      sid       = statement.sid
      effect    = statement.effect
      actions   = statement.actions
      resources = statement.resources
      dynamic "condition" {
        for_each = {
          for condition in lookup(statement, "conditions", []) :
          sha1(jsonencode(condition)) => condition
        }
        content {
          test     = condition.test
          variable = condition.variable
          values   = condition.values
        }
      }
    }
  }
}

data "aws_ecr_repository" "task" {
  name = var.ecr_repo
}

data "aws_ecr_image" "task" {
  count           = var.container.digest != null ? 1 : 0
  repository_name = data.aws_ecr_repository.task.name
  image_digest    = var.container.digest
}

data "aws_secretsmanager_secret" "cluster" {
  arn = var.cluster_secrets
}

data "aws_security_group" "cluster" {
  id = var.cluster_sg
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}
