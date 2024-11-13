# Current Account
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# VPC
data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "aws_subnet" "vpc_subnets" {
  for_each = toset(var.vpc_subnet_ids)
  id       = each.value
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_security_group" "inbound" {
  for_each = toset(var.security_groups)
  id       = each.value
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
  domain      = var.acm_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

# ECS
data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.cluster_name
}

# KMS
data "aws_kms_alias" "ecr" {
  name = "alias/aws/ecr"
}


# ECR
data "aws_ecr_lifecycle_policy_document" "ecr" {
  rule {
    priority    = 1
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
    priority    = 10
    description = "Expire build cache after 7 days."
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["cache*"]
      count_type       = "sinceImagePushed"
      count_unit       = "days"
      count_number     = 7
    }
  }
}
