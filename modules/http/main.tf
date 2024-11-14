# VPC Security Groups
## Load Balancer
resource "aws_security_group" "alb_sg" {
  description = "The security group associated with the ALB."
  name        = "${var.id}-${var.container.name}-alb-sg"
  vpc_id      = var.vpc_id
  tags = merge({
    Name = "${var.id}-${var.container.name}-alb-sg",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_https" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow all HTTPS traffic."
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-${var.container.name}-alb-sg-https",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_http" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow all HTTP traffic."
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-${var.container.name}-alb-sg-http",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_all" {
  security_group_id = aws_security_group.alb_sg.id
  description       = "Allow all outbound traffic."
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-${var.container.name}-alb-sg-all",
    TFID = var.id
  }, var.aws_tags)
}
## Secrets
resource "aws_secretsmanager_secret" "http_secrets" {
  name = "${var.id}-${var.container.name}-svc-secrets"
  tags = merge({
    Name = "${var.id}-${var.container.name}-svc-secrets",
    TFID = var.id
  }, var.aws_tags)
}
## Service
resource "aws_security_group" "http_sg" {
  name   = "${var.id}-${var.container.name}-svc-sg"
  vpc_id = var.vpc_id
  tags = merge({
    Name = "${var.id}-${var.container.name}-svc-sg",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "http_sg" {
  security_group_id            = aws_security_group.http_sg.id
  description                  = "Allow traffic on port ${var.container.port} from the load balancer."
  from_port                    = var.container.port
  to_port                      = var.container.port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb_sg.id
  tags = merge({
    Name = "${var.id}-${var.container.name}-svc-sg-https",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_ingress_rule" "http_sg_inbound" {
  for_each                     = data.aws_security_group.inbound
  description                  = "Allow all traffic from specified security groups."
  security_group_id            = aws_security_group.http_sg.id
  ip_protocol                  = -1
  referenced_security_group_id = each.value.id
  tags = merge({
    Name = "${var.id}-${var.container.name}-svc-sg-inbound-${each.key}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_vpc_security_group_egress_rule" "http_all" {
  description       = "Allow all outbound traffic."
  security_group_id = aws_security_group.http_sg.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  tags = merge({
    Name = "${var.id}-${var.container.name}-svc-sg-all",
    TFID = var.id
  }, var.aws_tags)
}
# IAM
## Container
resource "aws_iam_role" "task_role" {
  name_prefix        = "ECSTaskRole_"
  description        = "Task role that is assumed by running containers."
  assume_role_policy = data.aws_iam_policy_document.ecs_trust_policy.json
  tags = merge({
    Name = "ECSTaskRole"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_policy" "task_policy" {
  name_prefix = "ECSTaskPolicy_"
  description = "Policies that are granted to running containers."
  policy      = data.aws_iam_policy_document.task_policy.json
  tags = merge({
    Name = "ECSTaskPolicy"
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

# Elastic Load Balancing
## Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.id}-${var.container.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in var.vpc_subnet_ids : subnet]
  tags = merge({
    Name = "${var.id}-${var.container.name}-alb",
    TFID = var.id
  }, var.aws_tags)
}

## Target Group
resource "aws_lb_target_group" "http_tg" {
  name                 = "${var.id}-${var.container.name}-tg"
  deregistration_delay = 300
  port                 = 80
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
  lifecycle {
    replace_triggered_by = [aws_lb_target_group.http_tg]
  }
  load_balancer_arn = aws_lb.alb.arn
  certificate_arn   = data.aws_acm_certificate.alb_certificate.arn
  port              = 443
  protocol          = "HTTPS"
  tags = merge({
    Name = "${var.id}-${var.container.name}-alb-https",
    TFID = var.id
  }, var.aws_tags)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_tg.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  tags = merge({
    Name = "${var.id}-${var.container.name}-alb-http",
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

# ECR
resource "aws_ecr_repository" "http_repo" {
  name                 = "${var.id}-${var.container.name}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  tags = merge({
    Name = "${var.id}-${var.container.name}",
    TFID = var.id
  }, var.aws_tags)
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = data.aws_kms_alias.ecr.target_key_arn
  }
}

resource "aws_ecr_lifecycle_policy" "http_repo_lifecycle" {
  repository = aws_ecr_repository.http_repo.name
  policy     = data.aws_ecr_lifecycle_policy_document.ecr.json
}

# ECS
## Task definition
resource "aws_ecs_task_definition" "http" {
  family             = "${var.id}-${var.container.name}-task-definition"
  task_role_arn      = aws_iam_role.task_role.arn
  execution_role_arn = data.aws_iam_role.task_execution_role.arn
  network_mode       = "awsvpc"
  cpu                = var.container.cpu
  memory             = var.container.memory
  tags = merge({
    Name = "${var.id}-${var.container.name}-task-definition",
    TFID = var.id
  }, var.aws_tags)
  container_definitions = jsonencode([
    merge(
      {
        name  = var.container.name
        image = "${aws_ecr_repository.http_repo.repository_url}:${var.container.tag}"
        portMappings = [{
          containerPort = var.container.port
          hostPost      = var.container.port
          protocol      = "tcp"
          appProtocol   = "http"
        }],
      essential = true },
      length(var.container.command) > 0 ? { command = var.container.command } : {},
      { environment = var.container.environment
        secrets = [
          for key in var.container.secret_keys :
          {
            name      = key,
            valueFrom = "${aws_secretsmanager_secret.http_secrets.arn}:${key}::"
          }
        ]
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
      }
    )
  ])
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

## Service
resource "aws_ecs_service" "http" {
  depends_on             = [aws_iam_role.task_role]
  name                   = "${var.id}-${var.container.name}-svc"
  cluster                = data.aws_ecs_cluster.ecs_cluster.arn
  task_definition        = aws_ecs_task_definition.http.arn
  desired_count          = var.scale_policy.min_capacity
  enable_execute_command = true

  # Tags
  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"
  tags = merge({
    Name = "${var.id}-${var.container.name}-svc",
    TFID = var.id
  }, var.aws_tags)
  # ECS deployment configuration
  force_new_deployment = true
  triggers = {
    redeployment = plantimestamp()
  }
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  # wait_for_steady_state              = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Network configuration
  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.http_sg.id, data.aws_security_group.inbound[*].id]
    subnets          = data.aws_subnet.vpc_subnets[*].id
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.http_tg.arn
    container_name   = var.container.name
    container_port   = var.container.port
  }

  # Compute configuration
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 3
  }
}

## Autoscaling
resource "aws_appautoscaling_target" "http_asg" {
  max_capacity       = var.scale_policy.max_capacity
  min_capacity       = var.scale_policy.min_capacity
  resource_id        = "service/${data.aws_ecs_cluster.ecs_cluster.cluster_name}/${aws_ecs_service.http.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags = merge({
    Name = "${var.id}-${var.container.name}-asg",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_appautoscaling_policy" "http_asg_policy" {
  name               = "${var.id}-${var.container.name}-cpu-asg-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.http_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.http_asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.http_asg.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.scale_policy.cpu_target
    scale_in_cooldown  = var.scale_policy.scale_in_cooldown
    scale_out_cooldown = var.scale_policy.scale_out_cooldown
  }
}
