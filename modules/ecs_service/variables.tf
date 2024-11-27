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

variable "cluster_secrets" {
  description = "The ARN of the secrets manager secret containing the ECS cluster secrets."
  type        = string
}

variable "task_execution_role" {
  description = "The name of the IAM role that the ECS task orchestrator must assume."
  type        = string
}

# ALB
variable "load_balancer" {
  description = "The configuration to use for the Load Balancer."
  type = object(
    {
      public          = optional(bool, true)
      security_groups = optional(list(string), [])
      prefix_lists    = optional(list(string), [])
      waf             = optional(bool, false)
      tls = optional(
        object(
          {
            domain = string
          }
        )
      )
    }
  )
}

variable "acm_domain" {
  description = "The domain to use for the ACM certificate."
  type        = string
  nullable    = true
  default     = null
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

# Container
variable "ecr_repo" {
  description = "The ECR repo in which the service task images are stored."
  type        = string
}

variable "container" {
  description = "The container definition for the main ECS task."
  type = object({
    name    = string
    tag     = optional(string)
    port    = number
    cpu     = number
    memory  = number
    command = optional(list(string))
    environment = list(object({
      name  = string
      value = string
    }))
    secret_keys         = optional(list(string), [])
    cluster_secret_keys = optional(list(string), [])
    health_check_route  = optional(string, "/")
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


variable "secrets" {
  description = "A set of secrets to store on Secrets Manager for this service."
  type        = map(string)
  nullable    = true
  default     = null
  sensitive   = true
}
