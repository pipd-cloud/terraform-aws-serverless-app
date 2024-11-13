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

variable "source_snapshot" {
  description = "The snapshot from which to create the database."
  type        = string
  nullable    = true
  default     = null
}

variable "engine_version" {
  description = "The version of the engine to deploy."
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = var.source_snapshot != null || var.engine_version != null
    error_message = "Either the engine version or the RDS snapshot ID must be provided"
  }
}

variable "instance_count" {
  description = "The number of instances in the cluster."
  type        = number
  default     = 2
  validation {
    condition     = var.instance_count > 0
    error_message = "The cluster instance count must be larger than 0."
  }
}

variable "acu_config" {
  description = "Minimum and maximum ACU to allocate to instances in the cluster."
  type = object({
    min = number
    max = number
  })
  default = {
    min = 0.5
    max = 1
  }
}

variable "proxy" {
  description = "Whether to create an RDS proxy."
  type        = bool
  default     = false
}
