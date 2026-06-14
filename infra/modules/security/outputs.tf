output "ui_alb_security_group_id" {
  description = "Security group ID for the public UI ALB."
  value       = aws_security_group.ui_alb.id
}

output "backend_alb_security_group_id" {
  description = "Security group ID for the internal backend ALB."
  value       = aws_security_group.backend_alb.id
}

output "app_security_group_id" {
  description = "Security group ID for the application compute tier."
  value       = aws_security_group.app.id
}

output "ui_instance_security_group_id" {
  description = "Security group ID for the UI compute tier."
  value       = aws_security_group.ui_instance.id
}

output "backend_instance_security_group_id" {
  description = "Security group ID for the backend compute tier."
  value       = aws_security_group.app.id
}

output "security_group_ids" {
  description = "All security groups created by this module."
  value = {
    ui_alb      = aws_security_group.ui_alb.id
    backend_alb = aws_security_group.backend_alb.id
    app         = aws_security_group.app.id
    ui_instance = aws_security_group.ui_instance.id
    backend_instance = aws_security_group.app.id
  }
}
