resource "aws_ecr_repository" "task" {
  name                 = "${var.id}-${var.repo}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = merge({
    Name = "${var.id}-${var.repo}",
    TFID = var.id
  }, var.aws_tags)
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "task" {
  repository = aws_ecr_repository.task.name
  policy     = data.aws_ecr_lifecycle_policy_document.task.json
}

resource "aws_ecr_repository" "buildcache" {
  name                 = "${var.id}-${var.repo}-buildcache"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  tags = merge({
    Name = "${var.id}-${var.repo}-buildcache",
    TFID = var.id
  }, var.aws_tags)
  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "buildcache" {
  repository = aws_ecr_repository.buildcache.name
  policy     = data.aws_ecr_lifecycle_policy_document.buildcache.json
}
