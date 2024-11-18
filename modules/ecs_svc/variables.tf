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

variable "cluster_sg" {
  description = "The ID of the ECS cluster security group."
  type        = string
}

variable "sns_topic" {
  description = "The ARN of the SNS topic to which to send notifications."
  type        = string
}

variable "cluster_name" {
  description = "The name of the ECS cluster ARN on which the services are run."
  type        = string
}

variable "task_execution_role" {
  description = "The name of the IAM role that the ECS task orchestrator must assume."
  type        = string
}

# ALB
variable "alb" {
  description = "Whether the application is fronted by an ALB."
  type        = bool
  default     = false
}

variable "acm_domain" {
  description = "The domain to use for the ACM certificate."
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = !var.alb || var.acm_domain != null
    error_message = "The variable 'acm_domain' must be set when 'alb' is true."
  }
}

# IAM
variable "managed_policies" {
  description = "List of managed policies that are associated with running tasks."
  type        = list(string)
  default     = []
}

variable "policy" {
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
}


variable "container" {
  description = "The container definition for the main ECS task."
  type = object({
    name    = string
    port    = number
    cpu     = number
    memory  = number
    command = optional(list(string))
    environment = list(object({
      name  = string
      value = string
    }))
    secret_keys        = optional(list(string), [])
    health_check_route = optional(string, "/")
  })
}

variable "scale_policy" {
  description = "The scaling policy for the ECS service."
  type = object({
    min_capacity       = number
    max_capacity       = number
    cpu_target         = optional(number, 70)
    memory_target      = optional(number, 70)
    scale_in_cooldown  = optional(number, 60)
    scale_out_cooldown = optional(number, 60)
  })
}


