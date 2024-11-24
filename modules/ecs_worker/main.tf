# VPC Security Groups
## Secrets
resource "aws_secretsmanager_secret" "worker_secrets" {
  name_prefix = "${var.id}-${var.container.name}-worker-secrets"
  description = "Secrets used by the ${var.container.name} container."
  tags = merge({
    Name = "${var.id}-${var.container.name}-worker-secrets",
    TFID = var.id
  }, var.aws_tags)
}

# IAM
## Container
resource "aws_iam_role" "task_role" {
  name_prefix        = "ECSWorkerTaskRole_"
  description        = "Task role that is assumed by running containers."
  assume_role_policy = data.aws_iam_policy_document.ecs_trust_policy.json
  tags = merge({
    Name = "ECSWorkerTaskRole"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_policy" "task_policy" {
  name_prefix = "ECSWorkerTaskPolicy_"
  description = "Policies that are granted to running containers."
  policy      = data.aws_iam_policy_document.task_policy.json
  tags = merge({
    Name = "ECSWorkerTaskPolicy"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}

resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each   = data.aws_iam_policy.task_managed_policies
  role       = aws_iam_role.task_role.name
  policy_arn = each.value.arn
}


# ECS
## Task definition
resource "aws_ecs_task_definition" "worker" {
  family             = "${var.id}-${var.container.name}-worker-task"
  task_role_arn      = aws_iam_role.task_role.arn
  execution_role_arn = data.aws_iam_role.task_execution_role.arn
  network_mode       = "awsvpc"
  cpu                = var.container.cpu
  memory             = var.container.memory
  tags = merge({
    Name = "${var.id}-${var.container.name}-worker-task",
    TFID = var.id
  }, var.aws_tags)
  container_definitions = jsonencode([
    merge(
      {
        name      = var.container.name
        image     = data.aws_ecr_image.worker.image_uri
        essential = true
      },
      length(var.container.command) > 0 ? { command = var.container.command } : {},
      { environment = var.container.environment
        secrets = concat(
          [
            for key in var.container.secret_keys :
            {
              name      = key,
              valueFrom = "${aws_secretsmanager_secret.worker_secrets.arn}:${key}::"
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
      }
    )
  ])
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

## Service
resource "aws_ecs_service" "worker" {
  depends_on             = [aws_iam_role.task_role]
  name                   = "${var.id}-${var.container.name}-worker"
  cluster                = data.aws_ecs_cluster.ecs_cluster.arn
  task_definition        = aws_ecs_task_definition.worker.arn
  desired_count          = var.scale_policy.min_capacity
  enable_execute_command = true

  # Tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"
  tags = merge({
    Name = "${var.id}-${var.container.name}-worker",
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
    security_groups  = [data.aws_security_group.cluster.id]
    subnets          = data.aws_subnet.vpc_private_subnets[*].id
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
resource "aws_appautoscaling_target" "worker_asg" {
  max_capacity       = var.scale_policy.max_capacity
  min_capacity       = var.scale_policy.min_capacity
  resource_id        = "service/${data.aws_ecs_cluster.ecs_cluster.cluster_name}/${aws_ecs_service.worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = merge({
    Name = "${var.id}-${var.container.name}-worker-asg",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_appautoscaling_policy" "worker_asg_policy" {
  name               = "${var.id}-${var.container.name}-cpu-asg-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.worker_asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker_asg.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.scale_policy.cpu_target
    scale_in_cooldown  = var.scale_policy.scale_in_cooldown
    scale_out_cooldown = var.scale_policy.scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "worker_asg_memory_policy" {
  name               = "${var.id}-${var.container.name}-memory-asg-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.worker_asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker_asg.service_namespace
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
  dimensions = {
    ClusterName = data.aws_ecs_cluster.ecs_cluster.cluster_name
    ServiceName = aws_ecs_service.service.name
  }
  tags = merge({
    Name = "${var.id}-${var.container.name}-worker-cpu-alarm",
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
  dimensions = {
    ClusterName = data.aws_ecs_cluster.ecs_cluster.cluster_name
    ServiceName = aws_ecs_service.service.name
  }
  tags = merge({
    Name = "${var.id}-${var.container.name}-worker-memory-alarm",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_cloudwatch_composite_alarm" "service_alarm" {
  alarm_name    = "${aws_ecs_service.service.name}-composite-alarm"
  alarm_rule    = "ALARM(\"${aws_cloudwatch_metric_alarm.cpu.alarm_name}\") OR ALARM(\"${aws_cloudwatch_metric_alarm.memory.alarm_name}\")"
  alarm_actions = [var.sns_topic]
  ok_actions    = [var.sns_topic]
  tags = merge({
    Name = "${var.id}-${var.container.name}-worker-alarm",
    TFID = var.id
  }, var.aws_tags)
  depends_on = [
    aws_cloudwatch_metric_alarm.cpu,
    aws_cloudwatch_metric_alarm.memory
  ]
}

