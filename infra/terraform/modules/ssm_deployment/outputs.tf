output "backend_automation_document_name" {
  description = "Name of the backend SSM Automation document."
  value       = aws_ssm_document.backend_deploy.name
}

output "ui_automation_document_name" {
  description = "Name of the UI SSM Automation document."
  value       = aws_ssm_document.ui_deploy.name
}

output "backend_association_id" {
  description = "Association ID for backend deployment automation."
  value       = aws_ssm_association.backend_deploy.association_id
}

output "ui_association_id" {
  description = "Association ID for UI deployment automation."
  value       = aws_ssm_association.ui_deploy.association_id
}
