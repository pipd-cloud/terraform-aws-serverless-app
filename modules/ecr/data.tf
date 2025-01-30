data "aws_ecr_lifecycle_policy_document" "task" {
  dynamic "rule" {
    for_each = var.lifecycle_policy_rules
    content {
      priority    = rule.key
      description = rule.value.description
      selection {
        tag_status      = rule.value.tag_status
        tag_prefix_list = rule.value.tag_prefix_list
        count_type      = rule.value.count_type
        count_unit      = rule.value.count_unit
        count_number    = rule.value.count_number
      }
    }
  }
}
