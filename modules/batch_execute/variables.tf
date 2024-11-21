# Common Variables
# Required variables
variable "id" {
  description = "A unique identifier for this deployment, used for tracking and organization."
  type        = string
}

# Optional variables
variable "aws_tags" {
  description = "Additional AWS tags to apply to resources within this module for better organization and filtering."
  type        = map(string)
  default     = {}
}

# Module Variables
# AWS Infrastructure
variable "vpc_id" {
  description = "The ID of the AWS VPC that provides the network foundation for the ECS cluster."
  type        = string
}

variable "vpc_private_subnets" {
  description = "A list of IDs of private subnets within the VPC, used for deploying ECS tasks securely."
  type        = list(string)
}

# Secret Management
variable "cluster_secrets" {
  description = "The ARN of the Secrets Manager secret that stores sensitive information needed by the ECS cluster, such as database credentials or API keys."
  type        = string
}

# Security
variable "cluster_sg" {
  description = "The ID of the security group that controls network traffic to and from the ECS cluster."
  type        = string
}

# Notifications
variable "sns_topic" {
  description = "The ARN of the SNS topic to which notifications are sent."
  type        = string
}

# Task Execution
variable "task_execution_role" {
  description = "The name of the IAM role that the ECS task orchestrator will assume to perform actions on your behalf, such as launching tasks and accessing resources."
  type        = string
}

# IAM Configuration
variable "managed_policies" {
  description = "A list of managed IAM policies that will be attached to the task role, granting it necessary permissions."
  type        = list(string)
  default     = []
}

variable "policy" {
  description = "A custom IAM policy that will be attached to the task role, providing specific permissions beyond those granted by managed policies."
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

# Container Definition
variable "container" {
  description = "The definition of the primary container within the ECS task, specifying its configuration and behavior."
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
    secret_keys         = optional(list(string), [])
    cluster_secret_keys = optional(list(string), [])
    health_check_route  = optional(string, "/")
  })
}
