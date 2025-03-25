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

variable "vpc_public_subnet_ids" {
  description = "The IDs of the public subnets in the VPC."
  type        = list(string)
  default     = []
}

variable "vpc_private_subnet_ids" {
  description = "The IDs of the private subnets in the VPC."
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

variable "cluster_snapshot" {
  description = "The cluster snapshot from which to create the database."
  type        = string
  nullable    = true
  default     = null
}

variable "instance_snapshot" {
  description = "The instance snapshot from which to create the database."
  type        = string
  nullable    = true
  default     = null
}

variable "engine" {
  description = "The engine to use for the database."
  type        = string
  default     = "postgresql"
  validation {
    condition     = contains(["mysql", "postgresql"], var.engine)
    error_message = "The engine must be either 'mysql' or 'postgresql'."
  }
}

variable "engine_version" {
  description = "The version of the engine to deploy."
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = var.cluster_snapshot == null || var.instance_snapshot == null || var.engine_version != null
    error_message = "Either the engine version or the RDS snapshot ID must be provided"
  }
}

variable "private_instance_count" {
  description = "The number of instances in the cluster."
  type        = number
  default     = 1
  validation {
    condition     = var.private_instance_count > 0
    error_message = "The cluster instance count must be larger than 0."
  }
}

variable "public_instance_count" {
  description = "The number of public instances in the cluster."
  type        = number
  default     = 0
  validation {
    condition     = var.public_instance_count == 0 || length(var.vpc_public_subnet_ids) != 0
    error_message = "Must "
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

variable "iam_auth_enabled" {
  description = "Whether to enable IAM authentication for the database."
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Whether to allow major version upgrades."
  type        = bool
  default     = false
}

variable "copy_tags_to_snapshot" {
  description = "Whether to copy tags to the database snapshot."
  type        = bool
  default     = true
}

variable "storage_encrypted" {
  description = "Whether to encrypt the database storage."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Whether to enable performance insights."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "The number of days to retain performance insights data."
  type        = number
  default     = 7
}

variable "monitoring_interval" {
  description = "The interval at which to monitor the database. (Enhanced Monitoring)"
  type        = number
  default     = 60
}

variable "preferred_backup_window" {
  description = "The preferred backup window for the database."
  type        = string
  default     = "00:00-05:00"
}

variable "preferred_maintenance_window" {
  description = "The preferred maintenance window for the database."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "deletion_protection" {
  description = "Set to true to enable delete protection for the DB cluster."
  type        = bool
  default     = true
}

variable "global_cluster" {
  description = "Set to true to create an RDS global cluster."
  type        = bool
  default     = false
}

variable "cloudwatch_log_group_exports" {
  description = "The list of logs to export to CloudWatch, e.g. ['postgresql']"
  type        = list(string)
  default     = []
}
