data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid     = "EC2AssumeRole"
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_ecr_pull" {
  statement {
    sid    = "ECRGetAuthToken"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPullImages"
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [
      for repo in aws_ecr_repository.app : repo.arn
    ]
  }
}

resource "aws_iam_role" "ec2_app" {
  name               = "${var.project_name}-${var.environment}-ec2-app"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "ec2_app_ecr_pull" {
  name   = "ecr-pull"
  role   = aws_iam_role.ec2_app.id
  policy = data.aws_iam_policy_document.ec2_ecr_pull.json
}

resource "aws_iam_role_policy_attachment" "ec2_app_ssm_core" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_app" {
  name = "${var.project_name}-${var.environment}-ec2-app-profile"
  role = aws_iam_role.ec2_app.name
}
