variable "project_name" {
  description = "Project identifier used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used in naming and tagging."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created."
  type        = string
}

variable "ui_alb_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the public UI ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ui_listener_ports" {
  description = "Listener ports exposed by the public UI ALB."
  type        = list(number)
  default     = [80, 443]
}

variable "backend_listener_port" {
  description = "Listener port exposed by the backend ALB."
  type        = number
  default     = 3011
}

variable "backend_alb_allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the backend ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Application port exposed by backend compute instances."
  type        = number
  default     = 3011
}

variable "runner_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into compute instances."
  type        = list(string)
  default     = []
}

variable "runner_ssh_security_group_ids" {
  description = "Security group IDs allowed to SSH into compute instances."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags to apply to resources."
  type        = map(string)
  default     = {}
}

