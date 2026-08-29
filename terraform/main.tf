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
