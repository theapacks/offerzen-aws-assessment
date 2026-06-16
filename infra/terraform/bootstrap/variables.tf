variable "aws_region" {
  description = "AWS region for the Terraform state bucket."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project identifier used to construct bucket names."
  type        = string
  default     = "offerzen-aws-assessment"
}

variable "environment" {
  description = "Environment name used in backend key prefix."
  type        = string
  default     = "dev"
}

variable "force_destroy" {
  description = "Allow destroying bucket with objects. Keep false for safety."
  type        = bool
  default     = false
}
