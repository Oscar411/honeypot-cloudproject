variable "project_name" {
  description = "Prefix for all resources"
  type        = string
  default     = "honeypot"
}

variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "slack_secret_arn" {
  description = "ARN of Slack webhook secret in Secrets Manager"
  type        = string
  default     = ""
}

variable "thehive_secret_arn" {
  description = "ARN of TheHive API key secret in Secrets Manager"
  type        = string
  default     = ""
}

