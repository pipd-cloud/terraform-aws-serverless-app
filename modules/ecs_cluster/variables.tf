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

variable "sns_topic" {
  description = "The ARN of the SNS topic to which to send notifications."
  type        = string
}

variable "security_groups" {
  description = "The IDs of the security groups that may access these resources."
  type        = list(string)
  default     = []
}

# Module Variables
variable "vpc_id" {
  description = "The ID of the AWS VPC."
  type        = string
}

variable "secrets" {
  description = "A set of secrets to store on Secrets Manager for this cluster."
  type        = map(string)
  nullable    = true
  default     = null
  sensitive   = true
}

variable "vpc_public_subnets" {
  description = "The IDs of the public subnets in the VPC."
  type        = list(string)
}

variable "load_balancer" {
  description = "The configuration to use for the Load Balancer."
  type = object(
    {
      public          = optional(bool, true)
      security_groups = optional(list(string), [])
      prefix_lists    = optional(list(string), [])
      waf             = optional(bool, false)
    }
  )
}

