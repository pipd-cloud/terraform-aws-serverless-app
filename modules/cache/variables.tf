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
variable "vpc_id" {
  description = "The ID of the AWS VPC."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "The IDs of the subnets in the VPC."
  type        = list(string)
}

variable "sns_topic" {
  description = "The ARN of the SNS topic to which to send notifications."
  type        = string
}

variable "security_groups" {
  description = "The IDs of the security groups that may access these resources."
  type        = list(string)
  default     = []
}

variable "serverless_config" {
  description = "The configuration for the cache."
  type = object({
    data_storage = object({
      min = number
      max = number
    })
    ecpu = object({
      min = number
      max = number
    })
    ttl = object({
      create = optional(string, "40m")
      update = optional(string, "80m")
      delete = optional(string, "40m")
    })
  })
  default = {
    data_storage = {
      min = 1
      max = 2
    }
    ecpu = {
      min = 1000
      max = 2000
    }
    ttl = {
      create = "40m"
      update = "80m"
      delete = "40m"
    }
  }
}

variable "serverless" {
  description = "Whether to use a serverless cache."
  type        = bool
  default     = true
}

variable "config" {
  description = "The configuration for the cache."
  type = object({
    auto_minor_version_upgrade = optional(bool, true)
    node_type                  = optional(string, "cache.t3.medium")
    transit_encryption_enabled = optional(bool, false)
    num_cache_nodes            = optional(number, 1)
    apply_immediately          = optional(bool, false)
    engine_version             = optional(string, "7.1")
    port                       = optional(number, 6379)
    parameter_group_family     = optional(string, "redis7")
    alarm_cpu_threshold        = optional(number, 70)
    maintenance_window         = optional(string, "sun:05:00-sun:06:00")
    parameters = optional(map(object({
      name  = string
      value = string
    })), {})
  })
  default = {}
}
