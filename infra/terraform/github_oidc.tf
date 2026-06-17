resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Well-known GitHub Actions OIDC thumbprint.
  # Ref: https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = local.common_tags
}

resource "aws_iam_role" "github_actions_ecr" {
  name               = "${var.project_name}-${var.environment}-github-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.github_actions_trust.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "github_actions_ecr" {
  name   = "ecr-push"
  role   = aws_iam_role.github_actions_ecr.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_role_policy" "github_actions_ssm_deploy" {
  name = "ssm-deploy"
  role = aws_iam_role.github_actions_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMStartAutomation"
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution",
          "ssm:DescribeAutomationExecutions"
        ]
        Resource = "*"
      },
      {
        Sid    = "PassSSMAutomationRole"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${var.environment}-ssm-automation"
        ]
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ssm.amazonaws.com"
          }
        }
      }
    ]
  })
}

