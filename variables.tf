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

variable "sns_topic" {
  description = "The ARN of the SNS topic to which to send notifications."
  type        = string
}

variable "ecs_cluster_inbound_sg_ids" {
  description = "The list of security groups that are allowed to access the ECS cluster resources."
  type        = list(string)
  default     = []
}

## HTTP Service
variable "http_vpc_subnet_ids" {
  description = "The list of subnet IDs to use for the HTTP service."
  type        = list(string)
  default     = []
}


variable "http_container" {
  description = "The container definition for the main ECS task."
  type = object({
    name    = string
    tag     = string
    port    = number
    cpu     = optional(number, 2048)
    memory  = optional(number, 4096)
    command = optional(list(string), [])
    environment = optional(list(object({
      name  = string
      value = string
    })), [])
    secret_keys        = optional(list(string), [])
    health_check_route = optional(string, "/")
  })
}
variable "http_policy" {
  description = "The IAM policy to associate with the task."
  type = list(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []
}

variable "http_scale_policy" {
  description = "The scaling policy for the ECS service."
  type = object({
    min_capacity       = optional(number, 1)
    max_capacity       = optional(number, 8)
    cpu_target         = optional(number, 70)
    scale_in_cooldown  = optional(number, 60)
    scale_out_cooldown = optional(number, 60)
  })
  default = {
    min_capacity       = 1
    max_capacity       = 8
    cpu_target         = 70
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

variable "http_acm_domain" {
  description = "The domain to use for the ACM certificate."
  type        = string
}

variable "http_managed_policies" {
  description = "Managed policies to grant to the HTTP service."
  type        = list(string)
  default     = []
}

## Database
variable "db_inbound_sg_ids" {
  description = "The list of security groups that may access the database."
  type        = list(string)
  default     = []
}


variable "db_vpc_subnet_ids" {
  description = "The IDs of the subnets in the VPC to use with the database."
  type        = list(string)
}

variable "db_source_snapshot" {
  description = "The snapshot from which to create the database."
  type        = string
  nullable    = true
  default     = null
}

variable "db_engine_version" {
  description = "The version of the engine to deploy."
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = var.db_source_snapshot != null || var.db_engine_version != null
    error_message = "Either the engine version or the RDS snapshot ID must be provided"
  }
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

# Cache
variable "cache_inbound_sg_ids" {
  description = "The list of security groups that may access the cache."
  type        = list(string)
  default     = []
}

variable "cache_vpc_subnet_ids" {
  description = "The IDs of the subnets in the VPC to use with the cache."
  type        = list(string)
}

variable "cache_config" {
  description = "The configuration for the cache."
  type = object({
    data_storage = object({
      min = optional(number, 1)
      max = optional(number, 10)
    })
    ecpu = object({
      min = optional(number, 1000)
      max = optional(number, 10000)
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
      max = 10
    }
    ecpu = {
      min = 1000
      max = 10000
    }
    ttl = {
      create = "40m"
      update = "80m"
      delete = "40m"
    }
  }
}
