# main.tf - Connect the root configuration to infrastructure modules

# References:
# Terraform modules

module "network" {
  source = "./modules/network"

  resource_prefix      = var.resource_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "web" {
  source = "./modules/web"

  resource_prefix = var.resource_prefix
  vpc_cidr        = var.vpc_cidr
  vpc_id          = module.network.vpc_id

  public_subnet_ids = module.network.public_subnet_ids
  private_subnet_id = module.network.private_subnet_ids[0]
  instance_type     = var.web_instance_type
}
