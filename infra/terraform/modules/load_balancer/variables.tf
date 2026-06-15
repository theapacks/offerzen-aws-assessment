variable "project_name" {
  description = "Project identifier used in resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name used in naming and tagging."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the load balancers will be deployed."
  type        = string
}

variable "subnet_map" {
  description = "Map of subnet types to their IDs for ALB placement."
  type = object({
    public  = list(string)
    private = list(string)
  })
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

variable "security_group_ids" {
  description = "Map of ALB security group IDs keyed by load balancer name."
  type        = map(string)
}

variable "tags" {
  description = "Common tags to apply to resources."
  type        = map(string)
  default     = {}
}

