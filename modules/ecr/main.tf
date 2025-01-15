resource "aws_ecr_repository" "task" {
  name                 = "${var.id}-${var.repo_name}"
  image_tag_mutability = var.
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
  tags = merge({
    Name = "${var.id}-${var.repo_name}",
    TFID = var.id
  }, var.aws_tags)
}

resource "aws_ecr_lifecycle_policy" "task" {
  repository = aws_ecr_repository.task.name
  policy     = data.aws_ecr_lifecycle_policy_document.task.json
}

