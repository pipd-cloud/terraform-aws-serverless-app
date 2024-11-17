# Current Account
data "aws_region" "current" {}

# VPC
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnet" "vpc_public_subnets" {
  for_each = toset(var.vpc_public_subnets)
  id       = each.value
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_subnet" "vpc_private_subnets" {
  for_each = toset(var.vpc_private_subnets)
  id       = each.value
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_security_group" "cluster" {
  id = var.cluster_sg
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

## Task Execution
data "aws_iam_role" "task_execution_role" {
  name = var.task_execution_role
}

## Task (Container)
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

# ACM
data "aws_acm_certificate" "alb_certificate" {
  count       = var.alb ? 1 : 0
  domain      = var.acm_domain
  most_recent = true
}

# ECS
data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.cluster_name
}


# ECR
data "aws_ecr_lifecycle_policy_document" "ecs_svc" {
  rule {
    priority    = 10
    description = "Expire untagged images after 30 days."
    selection {
      tag_status   = "untagged"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 30
    }
    action {
      type = "expire"
    }
  }

  rule {
    priority    = 20
    description = "Keep only the latest 30 images."
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["${var.container.name}-*"]
      count_type       = "imageCountMoreThan"
      count_number     = 30
    }
  }
}

data "aws_ecr_lifecycle_policy_document" "buildcache" {
  rule {
    priority    = 10
    description = "Expire build cache after 7 days."
    selection {
      tag_status   = "any"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 7
    }
  }
}

data "aws_ecr_image" "ecs_svc" {
  repository_name = aws_ecr_repository.ecs_svc_repo.name
  most_recent     = true
}
