data "aws_ecr_lifecycle_policy_document" "task" {
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
    description = "Keep only the latest 30 images (minimum of 30 days)."
    selection {
      tag_status       = "tagged"
      tag_pattern_list = ["*"]
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
