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
variable "vpc_public_subnets" {
  description = "The IDs of the public subnets in the VPC."
  type        = list(string)
}

variable "vpc_private_subnets" {
  description = "The IDs of the private subnets in the VPC."
  type        = list(string)
}

variable "sns_topic" {
  description = "The ARN of the SNS topic to which to send notifications."
  type        = string
}

variable "ecs_cluster_inbound_sg_ids" {
  description = "The list of security groups that are allowed to access the ECS cluster resources."
  type        = list(string)
  default     = []
}

variable "ecs_cluster_secrets" {
  description = "A set of secrets to store on Secrets Manager for the ECS cluster."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "ecs_load_balancer" {
  description = "The configuration to use for the Load Balancer."
  type = object(
    {
      domain          = optional(string)
      public          = optional(bool, true)
      security_groups = optional(list(string), [])
      prefix_lists    = optional(list(string), [])
      waf             = optional(bool, false)
    }
  )
}

variable "ecr_config" {
  description = "The configuration to use for the ECR repositories."
  type = list(
    object(
      {
        name                 = string
        image_tag_mutability = optional(string, "MUTABLE")
        lifecycle_policy_rules = optional(
          map(
            object(
              {
                description     = string
                tag_status      = string
                tag_prefix_list = optional(list(string), [])
                count_type      = string
                count_unit      = optional(string)
                count_number    = number
              }
            )
          ),
          {}
        )
      }
    )
  )
  default = []
}

variable "batch" {
  description = "The AWS Batch configuration to apply, if any."
  type = object(
    {
      iam_custom_policy = optional(
        list(
          object(
            {
              sid       = string
              effect    = string
              actions   = list(string)
              resources = list(string)
              conditions = optional(list(object({
                test     = string
                variable = string
                values   = list(string)
                }
                )
                ),
                []
              )
            }
          )
        ),
        []
      )
      iam_managed_policies = optional(list(string), [])
      batch_compute = optional(
        object(
          {
            type      = optional(string, "FARGATE_SPOT")
            max_vcpus = optional(number, 16)
          }
        ),
        {
          type      = "FARGATE_SPOT"
          max_vcpus = 16
        }
      )
    }
  )
  default = {}
}

## Database
variable "db_inbound_sg_ids" {
  description = "The list of security groups that may access the database."
  type        = list(string)
  default     = []
}

variable "db_cluster_snapshot" {
  description = "The cluster snapshot from which to create the database."
  type        = string
  nullable    = true
  default     = null
}

variable "db_instance_snapshot" {
  description = "The instance snapshot from which to create the database."
  type        = string
  nullable    = true
  default     = null
}

variable "db_engine" {
  description = "The engine to use for the database."
  type        = string
  default     = "postgresql"
  validation {
    condition     = contains(["mysql", "postgresql"], var.db_engine)
    error_message = "The engine must be either 'mysql' or 'postgresql'."
  }
}

variable "db_iam_auth_enabled" {
  description = "Whether to enable IAM authentication for the database."
  type        = bool
  default     = false
}

variable "db_allow_major_version_upgrade" {
  description = "Whether to allow major version upgrades for the database."
  type        = bool
  default     = false
}

variable "db_engine_version" {
  description = "The version of the engine to deploy."
  type        = string
  nullable    = true
}

variable "db_instance_count" {
  description = "The number of instances in the cluster."
  type        = number
  default     = 1
  validation {
    condition     = var.db_instance_count > 0
    error_message = "The cluster instance count must be larger than 0."
  }
}
variable "db_public_instance_count" {
  description = "The number of public instances in the DB cluster."
  type        = number
  default     = 0
  validation {
    condition     = var.db_public_instance_count >= 0
    error_message = "The number of public instances must be equal to, or greater than zero."
  }
}

variable "db_acu_config" {
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

variable "db_proxy" {
  description = "Whether to create an RDS proxy."
  type        = bool
  default     = false
}

variable "db_storage_encrypted" {
  description = "Whether to enable storage encryption for the database."
  type        = bool
  default     = true
}

variable "db_copy_tags_to_snapshot" {
  description = "Whether to copy tags to the database snapshot."
  type        = bool
  default     = true
}

variable "db_monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected."
  type        = number
  default     = 60
}

variable "db_performance_insights_enabled" {
  description = "Whether to enable Performance Insights for the database."
  type        = bool
  default     = true
}

variable "db_performance_insights_retention_period" {
  description = "The number of days to retain Performance Insights data."
  type        = number
  default     = 7
}

variable "db_preferred_backup_window" {
  description = "The daily time range during which automated backups are created."
  type        = string
  default     = "00:00-05:00"
}

variable "db_preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

# Cache
variable "cache_inbound_sg_ids" {
  description = "The list of security groups that may access the cache."
  type        = list(string)
  default     = []
}

variable "cache_serverless" {
  description = "Whether to use a serverless cache."
  type        = bool
  default     = true
}

variable "cache_config" {
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
    maintenance_window         = optional(string, "sun:05:00-sun:06:00")
    parameters = optional(map(object({
      name  = string
      value = string
    })), {})
  })
  default = {}
}


variable "cache_serverless_config" {
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
