# Network outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.network.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "external_alb_dns_name" {
  description = "DNS name of the external UI ALB"
  value       = try(module.load_balancer.load_balancers["ui"].dns_name, null)
}

output "external_alb_arn" {
  description = "ARN of the external UI ALB"
  value       = try(module.load_balancer.load_balancers["ui"].arn, null)
}

output "external_target_group_arn" {
  description = "ARN of the external ALB target group"
  value       = try(module.load_balancer.load_balancer_target_groups["ui"], null)
}

output "external_alb_security_group_id" {
  description = "Security group ID for the external ALB"
  value       = try(module.load_balancer.load_balancers["ui"].security_group_id, null)
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal backend ALB"
  value       = try(module.load_balancer.load_balancers["backend"].dns_name, null)
}

output "internal_alb_arn" {
  description = "ARN of the internal backend ALB"
  value       = try(module.load_balancer.load_balancers["backend"].arn, null)
}

output "internal_target_group_arn" {
  description = "ARN of the internal ALB target group"
  value       = try(module.load_balancer.load_balancer_target_groups["backend"], null)
}

output "internal_alb_security_group_id" {
  description = "Security group ID for the internal ALB"
  value       = try(module.load_balancer.load_balancers["backend"].security_group_id, null)
}

output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by tier."
  value       = { for key, repo in aws_ecr_repository.app : key => repo.repository_url }
}

output "ecr_backend_repository_url" {
  description = "ECR repository URL for the backend image."
  value       = try(aws_ecr_repository.app["backend"].repository_url, null)
}

output "ecr_ui_repository_url" {
  description = "ECR repository URL for the UI image."
  value       = try(aws_ecr_repository.app["ui"].repository_url, null)
}

output "github_actions_role_arn" {
  description = "IAM role ARN to set as AWS_ROLE_TO_ASSUME."
  value       = aws_iam_role.github_actions_ecr.arn
}

output "monitoring_alerts_topic_arn" {
  description = "SNS topic ARN used for infrastructure alerts."
  value       = try(module.monitoring[0].sns_topic_arn, null)
}

output "monitoring_alarm_names" {
  description = "CloudWatch alarm names created for basic infrastructure monitoring."
  value       = try(module.monitoring[0].alarm_names, [])
}

