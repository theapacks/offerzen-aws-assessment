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

variable "vpc_endpoints" {
  description = "Map of VPC endpoints to create. Key is a short name; value is an object with service_name and type (Interface or Gateway)."
  type = map(object({
    service_name = string
    type         = string
  }))
  default = {}
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

variable "instance_key_name" {
  description = "Optional EC2 key pair name to attach to launch templates for SSH access."
  type        = string
  default     = null
}

variable "runner_ssh_cidr_blocks" {
  description = "CIDR blocks allowed to SSH into application instances."
  type        = list(string)
  default     = []
}

variable "runner_ssh_security_group_ids" {
  description = "Security group IDs allowed to SSH into application instances."
  type        = list(string)
  default     = []
}

variable "monitoring" {
  description = "Monitoring and alerting configuration for CloudWatch alarms and SNS notifications."
  type = object({
    enabled                            = optional(bool, true)
    alarm_email_endpoint               = optional(string, null)
    alb_5xx_threshold                  = optional(number, 10)
    alb_target_response_time_threshold = optional(number, 1.5)
    unhealthy_host_count_threshold     = optional(number, 1)
    evaluation_periods                 = optional(number, 2)
    period_seconds                     = optional(number, 300)
  })
  default = {}
}

variable "ssm_deployment" {
  description = "SSM Automation deployment configuration for application rollout."
  type = object({
    enabled                   = optional(bool, true)
    image_tag                 = optional(string, "latest")
    backend_container_name    = optional(string, "rewards-backend")
    backend_container_port    = optional(number, 3011)
    backend_host_port         = optional(number, 3011)
    ui_container_name         = optional(string, "rewards-ui")
    ui_container_port         = optional(number, 80)
    ui_host_port              = optional(number, 80)
    ui_server_url             = optional(string, null)
    backend_secret_parameters = optional(map(string), {})
  })
  default = {}
}
