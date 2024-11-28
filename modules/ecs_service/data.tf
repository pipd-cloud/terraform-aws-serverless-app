# Common data sources
data "aws_region" "current" {}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

# VPC
data "aws_subnet" "vpc_public_subnets" {
  count = length(var.vpc_public_subnets)
  id    = var.vpc_public_subnets[count.index]
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_subnet" "vpc_private_subnets" {
  count = length(var.vpc_private_subnets)
  id    = var.vpc_private_subnets[count.index]
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

# IAM
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

data "aws_iam_role" "task_execution_role" {
  name = var.task_execution_role
}

data "aws_iam_policy" "task_managed_policies" {
  for_each = toset(var.managed_policies)
  name     = each.value
}

data "aws_iam_policy_document" "task_policy" {

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

# ECS cluster components
data "aws_security_group" "cluster" {
  id = var.cluster_sg
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_secretsmanager_secret" "cluster_secrets" {
  arn = var.cluster_secrets
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.cluster_name
}

# Load balancer configuration
data "aws_acm_certificate" "alb" {
  count       = var.load_balancer.tls != null ? 1 : 0
  domain      = var.load_balancer.tls.domain
  most_recent = true
}

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

# Service container image
data "aws_ecr_repository" "service" {
  name = var.ecr_repo
}

data "aws_ecr_image" "service" {
  repository_name = data.aws_ecr_repository.service.name
  image_digest    = var.container.digest
}
