locals {
  name_prefix = "${var.project_name}-${var.environment}"
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
            commands = [
              "set -euo pipefail",
              "if command -v dnf >/dev/null 2>&1; then PM=dnf; else PM=yum; fi",
              "sudo $PM install -y docker awscli",
              "sudo systemctl enable --now docker",
              "aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${var.ecr_registry}",
              "sudo docker pull ${var.backend_image_repository}:${var.image_tag}",
              "sudo docker rm -f ${var.backend_container_name} >/dev/null 2>&1 || true",
              "sudo docker run -d --name ${var.backend_container_name} --restart always -p ${var.backend_host_port}:${var.backend_container_port} -e PORT=${var.backend_container_port} ${var.backend_image_repository}:${var.image_tag}"
            ]
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
              "if command -v dnf >/dev/null 2>&1; then PM=dnf; else PM=yum; fi",
              "sudo $PM install -y docker awscli",
              "sudo systemctl enable --now docker",
              "aws ecr get-login-password --region ${var.aws_region} | sudo docker login --username AWS --password-stdin ${var.ecr_registry}",
              "sudo docker pull ${var.ui_image_repository}:${var.image_tag}",
              "sudo docker rm -f ${var.ui_container_name} >/dev/null 2>&1 || true",
              "sudo docker run -d --name ${var.ui_container_name} --restart always -p ${var.ui_host_port}:${var.ui_container_port} -e SERVER_URL=${var.ui_server_url} ${var.ui_image_repository}:${var.image_tag}"
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
