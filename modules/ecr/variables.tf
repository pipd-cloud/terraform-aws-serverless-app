# Common Variables
## Required
variable "id" {
  description = "The unique identifier for this deployment."
  type        = string
}

## Optional
variable "aws_tags" {
  description = "Additional AWS tags to apply to resources in this module."
  type        = map(string)
  default     = {}
}

# Module Variables
# Required
variable "repo_name" {
  description = "The name of the ECR repository to create."
  type        = string
}

# Optional
variable "image_tag_mutability" {
  description = "The image tag mutability setting for the repository."
  type        = string
  default     = "MUTABLE"
}

variable "lifecycle_policy_rules" {
  description = "The lifecycle policy rules to apply to the ECR repository."
  type = map(object({
    description     = string
    tag_status      = string
    tag_prefix_list = optional(list(string), [])
    count_type      = string
    count_unit      = optional(string)
    count_number    = number
  }))
  default = {}
}
