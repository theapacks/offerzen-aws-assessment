variable "project_name" {
  description = "Project identifier used in names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name (for example: dev, staging, prod)."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to SSM resources."
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region used for ECR authentication in automation commands."
  type        = string
}

variable "image_tag" {
  description = "Container image tag to deploy for backend and UI."
  type        = string
}

variable "ecr_registry" {
  description = "ECR registry hostname, for example account.dkr.ecr.region.amazonaws.com."
  type        = string
}

variable "backend_image_repository" {
  description = "Backend ECR repository path without tag."
  type        = string
}

variable "ui_image_repository" {
  description = "UI ECR repository path without tag."
  type        = string
}

variable "backend_container_name" {
  description = "Container name for backend service."
  type        = string
  default     = "rewards-backend"
}

variable "backend_container_port" {
  description = "Container port exposed by backend service."
  type        = number
  default     = 3011
}

variable "backend_host_port" {
  description = "Host port mapped to backend container port."
  type        = number
  default     = 3011
}

variable "ui_container_name" {
  description = "Container name for UI service."
  type        = string
  default     = "rewards-ui"
}

variable "ui_container_port" {
  description = "Container port exposed by UI service."
  type        = number
  default     = 80
}

variable "ui_host_port" {
  description = "Host port mapped to UI container port."
  type        = number
  default     = 80
}

variable "ui_server_url" {
  description = "Backend URL injected into UI container as SERVER_URL."
  type        = string
}

variable "ui_instance_name_tag" {
  description = "Value of the Name tag used to target UI instances."
  type        = string
}

variable "backend_instance_name_tag" {
  description = "Value of the Name tag used to target backend instances."
  type        = string
}

variable "backend_secret_parameters" {
  description = "Map of backend container environment variable names to SSM Parameter Store names."
  type        = map(string)
  default     = {}
}
