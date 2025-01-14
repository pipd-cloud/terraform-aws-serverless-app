data "aws_ecr_lifecycle_policy_document" "task" {
  rule {
    priority    = 10
    description = "Expire stale images after 90 days."
    selection {
      tag_status   = "any"
      count_type   = "sinceImagePushed"
      count_unit   = "days"
      count_number = var.task_expiry_days
    }
  }
  rule {
    priority    = 20
    description = "Expire build cache after 7 days."
    selection {
      tag_status      = "tagged"
      tag_prefix_list = [var.buildcache_tag_prefix  ]
      count_type      = "sinceImagePushed"
      count_unit      = "days"
      count_number    = var.buildcache_expiry_days
    }
  }
}
