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
  backend_listener_port = try(var.load_balancers["backend"].listener_port, 8080)
  app_port              = try(var.load_balancers["backend"].target_port, 8080)
  tags                  = local.common_tags
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

  project_name       = var.project_name
  environment        = var.environment
  tier_name          = "ui"
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.security.ui_instance_security_group_id]
  target_group_arns  = [module.load_balancer.load_balancers["ui"].target_group_arn]
  instance_type      = var.compute_tiers["ui"].instance_type
  ami_id             = data.aws_ssm_parameter.al2023_ami.value
  min_size           = var.compute_tiers["ui"].min_size
  max_size           = var.compute_tiers["ui"].max_size
  desired_capacity    = var.compute_tiers["ui"].desired_capacity
  app_port            = try(var.load_balancers["ui"].target_port, 80)
  tags                = local.common_tags
}

module "backend_asg" {
  source = "./modules/compute_asg"

  project_name       = var.project_name
  environment        = var.environment
  tier_name          = "backend"
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.backend_instance_security_group_id]
  target_group_arns  = [module.load_balancer.load_balancers["backend"].target_group_arn]
  instance_type      = var.compute_tiers["backend"].instance_type
  ami_id             = data.aws_ssm_parameter.al2023_ami.value
  min_size           = var.compute_tiers["backend"].min_size
  max_size           = var.compute_tiers["backend"].max_size
  desired_capacity    = var.compute_tiers["backend"].desired_capacity
  app_port            = try(var.load_balancers["backend"].target_port, 8080)
  tags                = local.common_tags
}


