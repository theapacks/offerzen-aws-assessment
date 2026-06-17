locals {
  name_prefix             = "${var.project_name}-${var.environment}"
  backend_secret_env_file = "/tmp/${var.project_name}-${var.environment}-backend-secrets.env"
  backend_secret_setup_commands = concat(
    length(var.backend_secret_parameters) > 0 ? [
      "sudo rm -f ${local.backend_secret_env_file}",
      "sudo install -m 600 /dev/null ${local.backend_secret_env_file}",
    ] : [],
    flatten([
      for env_name, parameter_name in var.backend_secret_parameters : [
        "backend_secret_value=$(aws ssm get-parameter --name '${parameter_name}' --with-decryption --query Parameter.Value --output text --region ${var.aws_region})",
        "printf '%s=%s\\n' '${env_name}' \"$backend_secret_value\" | sudo tee -a ${local.backend_secret_env_file} >/dev/null",
      ]
    ])
  )
  backend_secret_env_file_arg = length(var.backend_secret_parameters) > 0 ? " --env-file ${local.backend_secret_env_file}" : ""
  backend_secret_cleanup_commands = length(var.backend_secret_parameters) > 0 ? [
    "sudo rm -f ${local.backend_secret_env_file}",
  ] : []
}

resource "aws_ssm_document" "backend_deploy" {
  name            = "${local.name_prefix}-backend-deploy"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Install Docker and deploy backend container from ECR"
    parameters = {
      InstanceId = {
        type = "StringList"
      }
    }
    mainSteps = [
      {
        name   = "DeployBackendContainer"
        action = "aws:runCommand"
        inputs = {
          DocumentName = "AWS-RunShellScript"
          InstanceIds  = "{{ InstanceId }}"
          Parameters = {
            commands = concat([
              "set -euo pipefail",
              "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_registry}",
              "docker pull ${var.backend_image_repository}:${var.image_tag}",
              "docker rm -f ${var.backend_container_name} >/dev/null 2>&1 || true",
              ], local.backend_secret_setup_commands, [
              "docker run -d --name ${var.backend_container_name} --restart always -p ${var.backend_host_port}:${var.backend_container_port} -e PORT=${var.backend_container_port}${local.backend_secret_env_file_arg} ${var.backend_image_repository}:${var.image_tag}",
            ], local.backend_secret_cleanup_commands)
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_ssm_document" "ui_deploy" {
  name            = "${local.name_prefix}-ui-deploy"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Install Docker and deploy UI container from ECR"
    parameters = {
      InstanceId = {
        type = "StringList"
      }
    }
    mainSteps = [
      {
        name   = "DeployUiContainer"
        action = "aws:runCommand"
        inputs = {
          DocumentName = "AWS-RunShellScript"
          InstanceIds  = "{{ InstanceId }}"
          Parameters = {
            commands = [
              "set -euo pipefail",
              "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_registry}",
              "docker pull ${var.ui_image_repository}:${var.image_tag}",
              "docker rm -f ${var.ui_container_name} >/dev/null 2>&1 || true",
              "docker run -d --name ${var.ui_container_name} --restart always -p ${var.ui_host_port}:${var.ui_container_port} -e SERVER_URL=${var.ui_server_url} ${var.ui_image_repository}:${var.image_tag}"
            ]
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_ssm_association" "backend_deploy" {
  name                             = aws_ssm_document.backend_deploy.name
  association_name                 = "${local.name_prefix}-backend-deploy"
  automation_target_parameter_name = "InstanceId"

  targets {
    key    = "tag:Name"
    values = [var.backend_instance_name_tag]
  }
}

resource "aws_ssm_association" "ui_deploy" {
  name                             = aws_ssm_document.ui_deploy.name
  association_name                 = "${local.name_prefix}-ui-deploy"
  automation_target_parameter_name = "InstanceId"

  targets {
    key    = "tag:Name"
    values = [var.ui_instance_name_tag]
  }
}
