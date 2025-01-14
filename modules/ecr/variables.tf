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
variable "buildcache_tag_prefix" {
  description = "The prefix for build cache images."
  type        = string
  default     = "buildcache-"
}

variable "buildcache_expiry_days" {
  description = "The number of days to keep build cache images."
  type        = number
  default     = 7
}

variable "task_expiry_days" {
  description = "The number of days to keep task images."
  type        = number
  default     = 90
}
