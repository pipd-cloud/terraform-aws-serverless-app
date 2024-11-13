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

variable "config" {
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
