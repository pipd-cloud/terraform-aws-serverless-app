data "aws_ecr_lifecycle_policy_document" "task" {
  rule {
    priority    = 10
    description = "Expire stale images after 90 days."
    selection {
      tag_status   = "any"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = 90
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
