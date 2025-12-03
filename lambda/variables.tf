variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "metadata_bucket" {
  type        = string
  description = "S3 bucket name for storing metadata (e.g. honeypot-evidence-and-reports)"
}

variable "default_honeypot_instance" {
  type        = string
  description = "Fallback honeypot EC2 instance id (optional)"
  default     = ""
}

variable "slack_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for Slack (JSON {\"webhook_url\":\"...\"})"
  default     = ""
}

variable "thehive_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for TheHive (JSON {\"api_url\":\"...\",\"api_key\":\"...\"})"
  default     = ""
}