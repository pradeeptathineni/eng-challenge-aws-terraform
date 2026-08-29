# main.tf - Connect the root configuration to infrastructure modules

# References:
# Terraform modules
module "network" {
  source = "./modules/network"

  resource_prefix      = local.resource_prefix
  vpc_cidr             = local.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
}

module "web" {
  source = "./modules/web"

  resource_prefix = local.resource_prefix
  vpc_cidr        = local.vpc_cidr
  vpc_id          = module.network.vpc_id

  public_subnet_ids = module.network.public_subnet_ids
  private_subnet_id = module.network.private_subnet_ids[0]
  instance_type     = var.instance_type
}
