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
  count                        = length(data.aws_security_group.inbound)
  description                  = "Allows traffic from ${data.aws_security_group.inbound[count.index].name}."
  security_group_id            = aws_security_group.cluster_sg.id
  ip_protocol                  = -1
  referenced_security_group_id = data.aws_security_group.inbound[count.index].id
  tags = merge({
    Name = "${var.id}-ecs-cluster-sg-inbound-${data.aws_security_group.inbound[count.index].id}"
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

resource "aws_iam_role_policy_attachment" "task_executor_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_policy.arn
}

# ECS
resource "aws_ecs_cluster" "cluster" {
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

# SecretsManager
resource "aws_secretsmanager_secret" "cluster_secrets" {
  name_prefix = "${var.id}-ecs-cluster-secrets"
  description = "General secrets that are available to all ECS Services."
  tags = merge({
    Name = "${var.id}-ecs-cluster-secrets"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_secretsmanager_secret_version" "cluster" {
  secret_id     = aws_secretsmanager_secret.cluster_secrets.id
  secret_string = jsonencode(var.secrets)
}

## Load Balancer
resource "aws_security_group" "alb" {
  description = "The ECS cluster application load balancer security group."
  name        = "${var.id}-ecs-cluster-alb-sg"
  vpc_id      = var.vpc_id
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-sg",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_public" {
  count             = var.load_balancer.public && var.load_balancer.domain != null ? 1 : 0
  security_group_id = aws_security_group.alb.id
  description       = "Allow all HTTPS traffic from public sources."
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-https-public",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_sg" {
  count                        = var.load_balancer.domain != null ? length(data.aws_security_group.internal) : 0
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow all HTTPS traffic from internal sources."
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.internal[count.index].id
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-https-internal-${data.aws_security_group.internal[count.index].id}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_pl" {
  count             = var.load_balancer.domain != null ? length(data.aws_prefix_list.internal) : 0
  security_group_id = aws_security_group.alb.id
  description       = "Allow all HTTPS traffic from predefined IP ranges."
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.internal[count.index].id
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-https-${data.aws_security_group.internal[count.index].id}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_public" {
  count             = var.load_balancer.public ? 1 : 0
  security_group_id = aws_security_group.alb.id
  description       = "Allow all HTTP traffic from public sources."
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-sg-http-public",
    TFID = var.id
  }, var.aws_tags)
}
resource "aws_vpc_security_group_ingress_rule" "alb_http_sg" {
  count                        = length(data.aws_security_group.internal)
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow all HTTP traffic from internal sources."
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.internal[count.index].id
  tags = merge({
    name = "${var.id}-ecs-cluster-alb-http-internal-${data.aws_security_group.internal[count.index].id}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_pl" {
  count             = length(data.aws_security_group.internal)
  security_group_id = aws_security_group.alb.id
  description       = "Allow all HTTP traffic from predefined IP ranges."
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.internal[count.index].id
  tags = merge({
    name = "${var.id}-ecs-cluster-alb-http-${data.aws_prefix_list.internal[count.index].id}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic."
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-all",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_lb" "alb" {
  name               = "${var.id}-ecs-cluster-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnet.vpc_public_subnets[*].id
  dynamic "access_logs" {
    for_each = var.load_balancer.logs_bucket != null ? [0] : []
    content {
      bucket  = data.aws_s3_bucket.access_logs[0].bucket
      enabled = true
    }
  }
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb",
    TFID = var.id
  }, var.aws_tags)
}


resource "aws_lb_listener" "https_arn" {
  count             = var.load_balancer.acm_certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  certificate_arn   = var.load_balancer.acm_certificate_arn
  port              = 443
  protocol          = "HTTPS"
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-https",
    TFID = var.id
  }, var.aws_tags)
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.load_balancer.domain != null ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  certificate_arn   = data.aws_acm_certificate.alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-https",
    TFID = var.id
  }, var.aws_tags)
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener" "http" {
  count             = var.load_balancer.acm_certificate_arn != null || var.load_balancer.domain != null ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-http",
    TFID = var.id
  }, var.aws_tags)
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "http_fwd" {
  count             = var.load_balancer.acm_certificate_arn != null || var.load_balancer.domain != null ? 0 : 1
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  tags = merge({
    Name = "${var.id}-ecs-cluster-alb-http",
    TFID = var.id
  }, var.aws_tags)
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = 404
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_rejected_connections" {
  alarm_name          = "${var.id}-ecs-cluster-alb-rejected-connections-alarm"
  alarm_description   = "Maxed out connections on ECS cluster ALB ${aws_lb.alb.id}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  statistic           = "Sum"
  evaluation_periods  = 3
  period              = 60
  treat_missing_data  = "notBreaching"
  actions_enabled     = true
  ok_actions          = [var.sns_topic]
  alarm_actions       = [var.sns_topic]
  metric_name         = "RejectedConnectionCount"
  namespace           = "AWS/ApplicationELB"
  dimensions = {
    LoadBalancer = aws_lb.alb.arn_suffix
  }
  tags = merge(
    {
      Name = "${var.id}-ecs-cluster-alb-rejected-connections-alarm"
    }, var.aws_tags
  )
}
