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

variable "load_balancers" {
  description = "Map of load balancer configurations."
  type = map(object({
    internal                         = bool
    subnet_type                      = string # "public" or "private"
    enable_http                      = optional(bool, true)
    enable_https                     = optional(bool, false)
    ssl_certificate_arn              = optional(string, null)
    target_port                      = optional(number, 80)
    listener_port                    = optional(number, 80)
    health_check_path                = optional(string, "/health")
    health_check_interval            = optional(number, 30)
    health_check_timeout             = optional(number, 5)
    health_check_healthy_threshold   = optional(number, 2)
    health_check_unhealthy_threshold = optional(number, 2)
    allowed_cidr_blocks              = optional(list(string), ["0.0.0.0/0"])
    target_type                      = optional(string, "instance")
  }))
}

variable "compute_tiers" {
  description = "Map of compute tier configurations keyed by tier name."
  type = map(object({
    instance_type    = string
    min_size         = number
    max_size         = number
    desired_capacity = number
  }))
}

variable "enable_http" {
  description = "Enable HTTP listener on the load balancer."
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Enable HTTPS listener on the load balancer."
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS listener."
  type        = string
  default     = null
}

variable "health_check_path" {
  description = "Health check endpoint path for the load balancer."
  type        = string
  default     = "/health"
}

variable "enable_internal_alb" {
  description = "Enable the internal ALB for backend services."
  type        = bool
  default     = true
}

variable "backend_port" {
  description = "Port for the internal ALB target group."
  type        = number
  default     = 8080
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

variable "github_repository" {
  description = "GitHub repository."
  type        = string
}
