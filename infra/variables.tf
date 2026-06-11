variable "aws_region" {
  description = "AWS region where infrastructure will be created."
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Project identifier used in names and tags."
  type        = string
  default     = "offerzen-aws-assessment"
}

variable "environment" {
  description = "Environment name (for example: dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks keyed by availability zone."
  type        = map(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks keyed by availability zone."
  type        = map(string)
}

variable "create_internet_gateway" {
  description = "Whether to create an Internet Gateway in the network module."
  type        = bool
  default     = true
}

variable "additional_tags" {
  description = "Additional resource tags merged with the common tags."
  type        = map(string)
  default     = {}
}
