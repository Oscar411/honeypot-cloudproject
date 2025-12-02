variable "name" {
  type	      = string
  description = "Name prefix for resources"
  default     = "honeypot cowrie"
}

variable "instance_type { 
  type 	      = string
  description = "EC2 instance type" 
  default     = "t3.small"
}

variable "key_name" {
  type 	      = string 
  description = "Existing EC2 key pair name to allow SSH access" 
  default     = ""
}

variable "subnet_id" {
  type        = string 
  description = "Subnet ID in which to launch the instance" 
}

variable "vpc_id" {
  type        = string 
  description = "VPC id for SG attachment" 
}

variable "allowed_cidr" {
  type        = string 
  description = "CIDR allowed to access the honeypot ports"
  default     = "0.0.0.0/0"
}

variable "ami_owner" {
  type        = string
  description = "AMI owner" 
  default     = "13711241989" # Amazon Linux 2 official owner id" 
}

variable "tags" {
  type       = map(string) 
  default    = {
    Project  = "honeypot"
    Role     = "cowrie" 
  }
}

