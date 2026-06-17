data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

module "network" {
  source = "./modules/network"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  create_internet_gateway = var.create_internet_gateway
  vpc_endpoints           = var.vpc_endpoints
  aws_region              = var.aws_region
  tags                    = local.common_tags
}

module "security" {
  source = "./modules/security"

  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.network.vpc_id
  ui_alb_allowed_cidr_blocks = try(var.load_balancers["ui"].allowed_cidr_blocks, ["0.0.0.0/0"])
  ui_listener_ports = concat(
    try(var.load_balancers["ui"].enable_http, true) ? [try(var.load_balancers["ui"].listener_port, 80)] : [],
    try(var.load_balancers["ui"].enable_https, false) ? [443] : []
  )
  backend_listener_port           = try(var.load_balancers["backend"].listener_port, 3011)
  backend_alb_allowed_cidr_blocks = try(var.load_balancers["backend"].allowed_cidr_blocks, ["0.0.0.0/0"])
  app_port                        = try(var.load_balancers["backend"].target_port, 3011)
  runner_ssh_cidr_blocks          = var.runner_ssh_cidr_blocks
  runner_ssh_security_group_ids   = var.runner_ssh_security_group_ids
  tags                            = local.common_tags
}

module "load_balancer" {
  source = "./modules/load_balancer"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.network.vpc_id
  load_balancers = var.load_balancers
  security_group_ids = {
    ui      = module.security.ui_alb_security_group_id
    backend = module.security.backend_alb_security_group_id
  }
  subnet_map = {
    public  = module.network.public_subnet_ids
    private = module.network.private_subnet_ids
  }
  tags = local.common_tags
}

module "ui_asg" {
  source = "./modules/compute_asg"

  project_name              = var.project_name
  environment               = var.environment
  tier_name                 = "ui"
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.public_subnet_ids
  security_group_ids        = [module.security.ui_instance_security_group_id]
  target_group_arns         = [module.load_balancer.load_balancers["ui"].target_group_arn]
  instance_type             = var.compute_tiers["ui"].instance_type
  ami_id                    = data.aws_ssm_parameter.al2023_ami.value
  iam_instance_profile_name = aws_iam_instance_profile.ec2_app.name
  key_name                  = var.instance_key_name
  min_size                  = var.compute_tiers["ui"].min_size
  max_size                  = var.compute_tiers["ui"].max_size
  desired_capacity          = var.compute_tiers["ui"].desired_capacity
  app_port                  = try(var.load_balancers["ui"].target_port, 80)
  tags                      = local.common_tags
  user_data_extra           = <<-EOT
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
    docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repositories["ui"]}:${try(var.ssm_deployment.image_tag, "latest")}
    docker run -d --name ${try(var.ssm_deployment.ui_container_name, "rewards-ui")} --restart always -p ${try(var.ssm_deployment.ui_host_port, 80)}:${try(var.ssm_deployment.ui_container_port, 80)} -e SERVER_URL=http://${module.load_balancer.load_balancers["backend"].dns_name}:${try(var.load_balancers["backend"].listener_port, 3011)} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repositories["ui"]}:${try(var.ssm_deployment.image_tag, "latest")}
  EOT
}

module "backend_asg" {
  source = "./modules/compute_asg"

  project_name              = var.project_name
  environment               = var.environment
  tier_name                 = "backend"
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.private_subnet_ids
  security_group_ids        = [module.security.backend_instance_security_group_id]
  target_group_arns         = [module.load_balancer.load_balancers["backend"].target_group_arn]
  instance_type             = var.compute_tiers["backend"].instance_type
  ami_id                    = data.aws_ssm_parameter.al2023_ami.value
  iam_instance_profile_name = aws_iam_instance_profile.ec2_app.name
  key_name                  = var.instance_key_name
  min_size                  = var.compute_tiers["backend"].min_size
  max_size                  = var.compute_tiers["backend"].max_size
  desired_capacity          = var.compute_tiers["backend"].desired_capacity
  app_port                  = try(var.load_balancers["backend"].target_port, 3011)
  tags                      = local.common_tags
  user_data_extra           = <<-EOT
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
    docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repositories["backend"]}:${try(var.ssm_deployment.image_tag, "latest")}
    docker run -d --name ${try(var.ssm_deployment.backend_container_name, "rewards-backend")} --restart always -p ${try(var.ssm_deployment.backend_host_port, 3011)}:${try(var.ssm_deployment.backend_container_port, 3011)} -e PORT=${try(var.ssm_deployment.backend_container_port, 3011)} ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repositories["backend"]}:${try(var.ssm_deployment.image_tag, "latest")}
  EOT
}

module "monitoring" {
  count  = try(var.monitoring.enabled, true) ? 1 : 0
  source = "./modules/monitoring"

  project_name                       = var.project_name
  environment                        = var.environment
  tags                               = local.common_tags
  ui_alb_arn_suffix                  = module.load_balancer.load_balancers["ui"].arn_suffix
  backend_alb_arn_suffix             = module.load_balancer.load_balancers["backend"].arn_suffix
  ui_target_group_arn_suffix         = module.load_balancer.load_balancers["ui"].target_group_arn_suffix
  backend_target_group_arn_suffix    = module.load_balancer.load_balancers["backend"].target_group_arn_suffix
  ui_asg_name                        = module.ui_asg.asg_name
  backend_asg_name                   = module.backend_asg.asg_name
  ui_desired_capacity                = var.compute_tiers["ui"].desired_capacity
  backend_desired_capacity           = var.compute_tiers["backend"].desired_capacity
  alarm_email_endpoint               = try(var.monitoring.alarm_email_endpoint, null)
  alb_5xx_threshold                  = try(var.monitoring.alb_5xx_threshold, 10)
  alb_target_response_time_threshold = try(var.monitoring.alb_target_response_time_threshold, 1.5)
  unhealthy_host_count_threshold     = try(var.monitoring.unhealthy_host_count_threshold, 1)
  evaluation_periods                 = try(var.monitoring.evaluation_periods, 2)
  period_seconds                     = try(var.monitoring.period_seconds, 300)
}

module "ssm_deployment" {
  count  = try(var.ssm_deployment.enabled, true) ? 1 : 0
  source = "./modules/ssm_deployment"

  project_name              = var.project_name
  environment               = var.environment
  tags                      = local.common_tags
  aws_region                = var.aws_region
  image_tag                 = try(var.ssm_deployment.image_tag, "latest")
  ecr_registry              = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  backend_image_repository  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repositories["backend"]}"
  ui_image_repository       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${local.ecr_repositories["ui"]}"
  backend_container_name    = try(var.ssm_deployment.backend_container_name, "rewards-backend")
  backend_container_port    = try(var.ssm_deployment.backend_container_port, 3011)
  backend_host_port         = try(var.ssm_deployment.backend_host_port, 3011)
  ui_container_name         = try(var.ssm_deployment.ui_container_name, "rewards-ui")
  ui_container_port         = try(var.ssm_deployment.ui_container_port, 80)
  ui_host_port              = try(var.ssm_deployment.ui_host_port, 80)
  ui_server_url             = coalesce(try(var.ssm_deployment.ui_server_url, null), "http://${module.load_balancer.load_balancers["backend"].dns_name}:${try(var.load_balancers["backend"].listener_port, 8080)}")
  ui_instance_name_tag      = "${var.project_name}-${var.environment}-ui-instance"
  backend_instance_name_tag = "${var.project_name}-${var.environment}-backend-instance"
  backend_secret_parameters = merge(
    { APP_SECRET = aws_ssm_parameter.app_secret.name },
    try(var.ssm_deployment.backend_secret_parameters, {})
  )
}


