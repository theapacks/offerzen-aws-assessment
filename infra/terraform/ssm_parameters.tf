resource "random_password" "app_secret" {
  length  = 32
  special = true
}

resource "aws_ssm_parameter" "app_secret" {
  name  = "/${var.project_name}/${var.environment}/backend/app_secret"
  type  = "SecureString"
  value = random_password.app_secret.result

  tags = local.common_tags

  lifecycle {
    ignore_changes = [value]
  }
}
