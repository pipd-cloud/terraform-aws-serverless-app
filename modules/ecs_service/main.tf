# VPC Security Groups
## Load Balancer
resource "aws_security_group" "alb" {
  count       = var.load_balancer != null ? 1 : 0
  description = "The application load balancer (${var.container.name}) security group."
  name        = "${var.id}-${var.container.name}-service-alb-sg"
  vpc_id      = var.vpc_id
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-sg",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_public" {
  count             = var.load_balancer != null ? ((var.load_balancer.tls != null && var.load_balancer.public) ? 1 : 0) : 0
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all HTTPS traffic from public sources."
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-https-public",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_sg" {
  count                        = var.load_balancer != null ? (var.load_balancer.tls != null ? length(data.aws_security_group.internal) : 0) : 0
  security_group_id            = aws_security_group.alb[0].id
  description                  = "Allow all HTTPS traffic from internal sources."
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.internal[count.index].id
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-https-internal-${data.aws_security_group.internal[count.index].id}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_pl" {
  count             = var.load_balancer != null ? (var.load_balancer.tls != null ? length(data.aws_prefix_list.internal) : 0) : 0
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all HTTPS traffic from predefined IP ranges."
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.internal[count.index].id
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-https-${data.aws_security_group.internal[count.index].id}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_public" {
  count             = var.load_balancer != null ? (var.load_balancer.public ? 1 : 0) : 0
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all HTTP traffic from public sources."
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-sg-http-public",
    TFID = var.id
  }, var.aws_tags)
}
resource "aws_vpc_security_group_ingress_rule" "alb_http_sg" {
  count                        = var.load_balancer != null ? length(data.aws_security_group.internal) : 0
  security_group_id            = aws_security_group.alb[0].id
  description                  = "Allow all HTTP traffic from internal sources."
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = data.aws_security_group.internal[count.index].id
  tags = merge({
    name = "${var.id}-${var.container.name}-service-alb-http-internal-${data.aws_security_group.internal[count.index].id}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_pl" {
  count             = var.load_balancer != null ? length(data.aws_security_group.internal) : 0
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all HTTP traffic from predefined IP ranges."
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_prefix_list.internal[count.index].id
  tags = merge({
    name = "${var.id}-${var.container.name}-service-alb-http-${data.aws_prefix_list.internal[count.index].id}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  count             = var.load_balancer != null ? 1 : 0
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow all outbound traffic."
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-all",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_security_group" "service" {
  name   = "${var.id}-${var.container.name}-service-sg"
  vpc_id = var.vpc_id
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-sg",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "service_alb" {
  count                        = var.load_balancer != null ? 1 : 0
  security_group_id            = aws_security_group.service.id
  description                  = "Allow traffic on port ${var.container.port} from the load balancer."
  from_port                    = var.container.port
  to_port                      = var.container.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb[0].id
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "service_all" {
  description       = "Allow all outbound traffic."
  security_group_id = aws_security_group.service.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-all",
    TFID = var.id
  }, var.aws_tags)
}

## Secrets
resource "aws_secretsmanager_secret" "service" {
  name_prefix = "${var.id}-${var.container.name}-service-secrets"
  description = "Secrets used by the ${var.container.name} container."
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-secrets",
    TFID = var.id
  }, var.aws_tags)
}

# IAM
## Container
resource "aws_iam_role" "task" {
  name_prefix        = "ECSServiceTaskRole_"
  description        = "Task role that is assumed by running containers."
  assume_role_policy = data.aws_iam_policy_document.ecs_trust_policy.json
  tags = merge({
    Name = "ECSServiceTaskRole"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_policy" "task" {
  name_prefix = "ECSServiceTaskPolicy_"
  description = "Policies that are granted to running containers."
  policy      = data.aws_iam_policy_document.task_policy.json
  tags = merge({
    Name = "ECSServiceTaskPolicy"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task.arn
}

resource "aws_iam_role_policy_attachment" "task_managed" {
  for_each   = data.aws_iam_policy.task_managed_policies
  role       = aws_iam_role.task.name
  policy_arn = each.value.arn
}

# Load balancer
resource "aws_lb" "alb" {
  count              = var.load_balancer != null ? 1 : 0
  name               = "${var.id}-${var.container.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = data.aws_subnet.vpc_public_subnets[*].id
  tags = merge({
    Name = "${var.id}-${var.container.name}-alb",
    TFID = var.id
  }, var.aws_tags)
}

## Target Group
resource "aws_lb_target_group" "service" {
  count                = var.load_balancer != null ? 1 : 0
  name                 = "${var.id}-${var.container.name}-tg"
  deregistration_delay = 300
  port                 = var.container.port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  tags = merge({
    Name = "${var.id}-${var.container.name}-tg",
    TFID = var.id
  }, var.aws_tags)
  health_check {
    enabled             = true
    healthy_threshold   = 5
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = var.container.health_check_route
  }
}

## Listeners
resource "aws_lb_listener" "https" {
  count = var.load_balancer != null ? (var.load_balancer.tls != null ? 1 : 0) : 0
  lifecycle {
    replace_triggered_by = [aws_lb_target_group.service]
  }
  load_balancer_arn = aws_lb.alb[0].arn
  certificate_arn   = data.aws_acm_certificate.alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-https",
    TFID = var.id
  }, var.aws_tags)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[0].arn
  }
}

resource "aws_lb_listener" "http" {
  count             = var.load_balancer != null ? (var.load_balancer.tls != null ? 1 : 0) : 0
  load_balancer_arn = aws_lb.alb[0].arn
  port              = 80
  protocol          = "HTTP"
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-http",
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
  count             = var.load_balancer != null ? (var.load_balancer.tls == null ? 1 : 0) : 0
  load_balancer_arn = aws_lb.alb[0].arn
  port              = 80
  protocol          = "HTTP"
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-alb-http",
    TFID = var.id
  }, var.aws_tags)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service[0].arn
  }
}

# ECS
## Task definition
resource "aws_ecs_task_definition" "service" {
  family             = "${var.id}-${var.container.name}-service-task"
  task_role_arn      = aws_iam_role.task.arn
  execution_role_arn = data.aws_iam_role.task_execution_role.arn
  network_mode       = "awsvpc"
  cpu                = var.container.cpu
  memory             = var.container.memory
  tags = merge({
    Name = "${var.id}-${var.container.name}-service-task",
    TFID = var.id
  }, var.aws_tags)
  container_definitions = jsonencode([
    merge(
      {
        name  = var.container.name
        image = var.container.tag != null ? data.aws_ecr_image.service_requested[0].image_uri : data.aws_ecr_image.service_latest.image_uri
        portMappings = [{
          containerPort = var.container.port
          hostPost      = var.container.port
          protocol      = "tcp"
          appProtocol   = "http"
        }],
      essential = true },
      length(var.container.command) > 0 ? { command = var.container.command } : {},
      { environment = var.container.environment
        secrets = concat(
          [
            for key in var.container.secret_keys :
            {
              name      = key,
              valueFrom = "${aws_secretsmanager_secret.service.arn}:${key}::"
            }
          ],
          [
            for key in var.container.cluster_secret_keys :
            {
              name      = key,
              valueFrom = "${data.aws_secretsmanager_secret.cluster_secrets.arn}:${key}::"
            }
          ]
        )
        logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group         = "ecs/${var.id}/container/${var.container.name}",
            mode                  = "non-blocking",
            awslogs-create-group  = "true",
            max-buffer-size       = "25m",
            awslogs-region        = data.aws_region.current.name,
            awslogs-stream-prefix = "ecs"
          }
        }
      },
      var.load_balancer != null ? {
        healthCheck = {
          command = [
            "CMD-SHELL",
            "curl -f http://$${HOSTNAME}:${var.container.port}${var.container.health_check_route} || exit 1"
          ]
          interval    = 30
          timeout     = 15
          retries     = 3
          startPeriod = 60
        }
      } : {}
    )
  ])
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

## Service
resource "aws_ecs_service" "service" {
  depends_on             = [aws_iam_role.task]
  name                   = "${var.id}-${var.container.name}-sevice"
  cluster                = data.aws_ecs_cluster.ecs_cluster.arn
  task_definition        = aws_ecs_task_definition.service.arn
  desired_count          = var.scale_policy.min_capacity
  enable_execute_command = true

  # Tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"
  tags = merge({
    Name = "${var.id}-${var.container.name}-sevice",
    TFID = var.id
  }, var.aws_tags)
  # ECS deployment configuration
  force_new_deployment               = true
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  # wait_for_steady_state              = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Network configuration
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.service.id, data.aws_security_group.cluster.id]
    subnets          = data.aws_subnet.vpc_private_subnets[*].id
  }

  dynamic "load_balancer" {
    for_each = var.load_balancer != null ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.service[0].arn
      container_name   = var.container.name
      container_port   = var.container.port
    }
  }

  # Compute configuration
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 3
  }
}

## Autoscaling
resource "aws_appautoscaling_target" "service_asg" {
  max_capacity       = var.scale_policy.max_capacity
  min_capacity       = var.scale_policy.min_capacity
  resource_id        = "service/${data.aws_ecs_cluster.ecs_cluster.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = merge({
    Name = "${var.id}-${var.container.name}-sevice-asg",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_appautoscaling_policy" "service_asg_policy" {
  name               = "${var.id}-${var.container.name}-cpu-asg-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.service_asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_asg.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.scale_policy.cpu_target
    scale_in_cooldown  = var.scale_policy.scale_in_cooldown
    scale_out_cooldown = var.scale_policy.scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "service_asg_memory_policy" {
  name               = "${var.id}-${var.container.name}-memory-asg-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.service_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.service_asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_asg.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.scale_policy.memory_target
    scale_in_cooldown  = var.scale_policy.scale_in_cooldown
    scale_out_cooldown = var.scale_policy.scale_out_cooldown
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${aws_ecs_service.service.name}-cpu-alarm"
  alarm_description   = "CPU usage on ECS service ${aws_ecs_service.service.name} is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_policy.cpu_target
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  dimensions = {
    ClusterName = data.aws_ecs_cluster.ecs_cluster.cluster_name
    ServiceName = aws_ecs_service.service.name
  }
  tags = merge({
    Name = "${var.id}-${var.container.name}-sevice-cpu-alarm",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  alarm_name          = "${aws_ecs_service.service.name}-memory-alarm"
  alarm_description   = "Memory usage on ECS service ${aws_ecs_service.service.name} is too high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.scale_policy.memory_target
  alarm_actions       = [var.sns_topic]
  ok_actions          = [var.sns_topic]
  dimensions = {
    ClusterName = data.aws_ecs_cluster.ecs_cluster.cluster_name
    ServiceName = aws_ecs_service.service.name
  }
  tags = merge({
    Name = "${var.id}-${var.container.name}-sevice-memory-alarm",
    TFID = var.id
  }, var.aws_tags)
}

