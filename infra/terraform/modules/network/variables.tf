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

variable "private_subnets" {
  description = "Private subnet CIDR blocks keyed by AZ."
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

variable "vpc_endpoints" {
  description = "Map of VPC endpoints to create. Key is a short name used in resource naming. Interface endpoints attach to subnets; Gateway endpoints attach to route tables."
  type = map(object({
    service_name = string
    type         = string # "Interface" or "Gateway"
  }))
  default = {}
}

variable "aws_region" {
  description = "AWS region for the resources."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources."
  type        = map(string)
  default     = {}
}

