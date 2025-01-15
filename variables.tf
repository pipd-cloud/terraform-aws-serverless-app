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
  nullable    = true
  default     = null
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

variable "ecr_repo_name" {
  description = "The name of the ECR repository to create."
  type        = string
}

variable "ecr_image_tag_mutability" {
  description = "The image tag mutability setting for the repository."
  type        = string
  default     = "MUTABLE"
}

variable "ecr_buildcache_tag_prefix" {
  description = "The prefix for build cache images."
  type        = string
  default     = "buildcache-"
}

variable "ecr_buildcache_expiry_days" {
  description = "The number of days to keep build cache images."
  type        = number
  default     = 7
}

variable "ecr_task_expiry_days" {
  description = "The number of days to keep task images."
  type        = number
  default     = 90
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


variable "cache_config" {
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
