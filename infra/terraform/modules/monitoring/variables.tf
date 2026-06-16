variable "project_name" {
  description = "Project identifier used in names and tags."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to monitoring resources."
  type        = map(string)
  default     = {}
}

variable "ui_alb_arn_suffix" {
  description = "ARN suffix for the UI ALB."
  type        = string
}

variable "backend_alb_arn_suffix" {
  description = "ARN suffix for the backend ALB."
  type        = string
}

variable "ui_target_group_arn_suffix" {
  description = "ARN suffix for the UI target group."
  type        = string
}

variable "backend_target_group_arn_suffix" {
  description = "ARN suffix for the backend target group."
  type        = string
}

variable "ui_asg_name" {
  description = "Name of the UI Auto Scaling Group."
  type        = string
}

variable "backend_asg_name" {
  description = "Name of the backend Auto Scaling Group."
  type        = string
}

variable "ui_desired_capacity" {
  description = "Desired capacity used as minimum healthy in-service instance threshold for UI ASG."
  type        = number
}

variable "backend_desired_capacity" {
  description = "Desired capacity used as minimum healthy in-service instance threshold for backend ASG."
  type        = number
}

variable "alarm_email_endpoint" {
  description = "Optional email address subscribed to monitoring SNS topic."
  type        = string
  default     = null
}

variable "alb_5xx_threshold" {
  description = "Threshold for ALB target 5XX count alarms."
  type        = number
  default     = 10
}

variable "alb_target_response_time_threshold" {
  description = "Threshold (seconds) for ALB target response time alarms."
  type        = number
  default     = 1.5
}

variable "unhealthy_host_count_threshold" {
  description = "Threshold for ALB unhealthy host count alarms."
  type        = number
  default     = 1
}

variable "evaluation_periods" {
  description = "Number of periods over which data is compared to the specified threshold."
  type        = number
  default     = 2
}

variable "period_seconds" {
  description = "Period, in seconds, over which the specified statistic is applied."
  type        = number
  default     = 300
}
