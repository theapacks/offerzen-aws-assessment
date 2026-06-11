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

variable "availability_zones" {
  description = "Two or more AZs used for subnets and high availability."
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "additional_tags" {
  description = "Additional resource tags merged with the common tags."
  type        = map(string)
  default     = {}
}
