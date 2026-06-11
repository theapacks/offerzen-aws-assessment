variable "project_name" {
  description = "Project identifier used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used in naming and tagging."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks keyed by AZ."
  type        = map(string)
}

variable "enable_dns_support" {
  description = "Enable DNS support for the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC."
  type        = bool
  default     = true
}

variable "create_internet_gateway" {
  description = "Whether to create an Internet Gateway for the VPC."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to resources."
  type        = map(string)
  default     = {}
}

