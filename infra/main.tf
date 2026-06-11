module "network" {
  source = "./modules/network"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  create_internet_gateway = var.create_internet_gateway
  tags                    = local.common_tags
}

