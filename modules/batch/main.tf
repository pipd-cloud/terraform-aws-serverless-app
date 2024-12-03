resource "aws_iam_role" "task" {
  name_prefix        = "BatchTaskRole_"
  description        = "Task role that is assumed by running containers."
  assume_role_policy = data.aws_iam_policy_document.batch.json
  tags = merge({
    Name = "ECSServiceTaskRole"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_policy" "task" {
  name_prefix = "BatchTaskPolicy_"
  description = "Policies that are granted to running containers."
  policy      = data.aws_iam_policy_document.task.json
  tags = merge({
    Name = "BatchTaskPolicy"
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_iam_role_policy_attachment" "task" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task.arn
}

resource "aws_iam_role_policy_attachment" "task_managed" {
  for_each   = data.aws_iam_policy.task
  role       = aws_iam_role.task.name
  policy_arn = each.value.arn
}

resource "aws_iam_role" "batch" {
  name_prefix        = "BatchServiceRole_"
  description        = "Role that allows AWS Batch to call other AWS services on your behalf."
  assume_role_policy = data.aws_iam_policy_document.batch.json
  tags = merge(
    {
      Name = "BatchServiceRole"
      TFID = var.id
    },
  var.aws_tags)
}

resource "aws_iam_role_policy_attachment" "batch" {
  role       = aws_iam_role.batch.name
  policy_arn = data.aws_iam_policy.batch.arn
}

resource "aws_secretsmanager_secret" "task" {
  name_prefix = "${var.id}-${var.container.name}-task-secrets"
  description = "Secrets used by the ${var.container.name} Batch task."
  tags = merge({
    Name = "${var.id}-${var.container.name}-task-secrets",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_batch_compute_environment" "batch" {
  compute_environment_name = "${var.id}-batch-compute-environment"
  service_role             = aws_iam_role.batch.arn
  type                     = "MANAGED"
  tags = merge(
    {
      Name = "${var.id}-batch-compute-environment"
      TFID = var.id
    },
  var.aws_tags)
  compute_resources {
    max_vcpus          = var.batch_compute.max_vcpus
    type               = var.batch_compute.type
    subnets            = keys(data.aws_subnet.private)
    security_group_ids = [data.aws_security_group.cluster.id]
    tags               = var.aws_tags
  }
  depends_on = [aws_iam_role_policy_attachment.batch]
}

resource "aws_batch_job_queue" "batch" {
  name     = "${var.id}-batch-job-queue"
  priority = 1
  state    = "ENABLED"
  tags = merge(
    {
      Name = "${var.id}-batch-job-queue"
      TFID = var.id
    },
  var.aws_tags)
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.batch
  }
}

resource "aws_batch_job_definition" "batch" {
  count = var.container.digest != null ? 1 : 0
  name  = "${var.id}-batch-job"
  type  = "container"
  container_properties = jsonencode(
    merge(
      length(var.container.command) > 0 ? { command = var.container.command } : {},
      {
        image       = data.aws_ecr_image.task[0].image_uri
        environment = var.container.environment
        secrets = [
          for key in var.container.cluster_secret_keys :
          {
            name      = key,
            valueFrom = "${data.aws_secretsmanager_secret.cluster.arn}:${key}::"
          }
        ]
        resourceRequirements = [
          {
            type  = "VCPU"
            value = var.container.cpu
          },
          {
            type  = "MEMORY"
            value = tostring(var.container.memory * 1024)
          }
        ]
        executionRoleArn = data.aws_iam_role.task_execution.arn
        jobRoleArn       = aws_iam_role.task.arn
        logConfiguration = {
          logDriver = "awslogs",
          options = {
            awslogs-group         = "batch/${var.id}/container/${var.container.name}",
            mode                  = "non-blocking",
            awslogs-create-group  = "true",
            max-buffer-size       = "25m",
            awslogs-region        = data.aws_region.current.name,
            awslogs-stream-prefix = "ecs"
          }
        }
      }
    )
  )
  platform_capabilities = ["FARGATE"]
  propagate_tags        = true
  retry_strategy {
    attempts = var.container.attempts
  }
  tags = merge(
    {
      Name = "${var.id}-batch-job-queue"
      TFID = var.id
    },
  var.aws_tags)
}
