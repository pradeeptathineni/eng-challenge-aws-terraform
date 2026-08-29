# main.tf - Connect the root configuration to infrastructure modules

# References:
# Terraform modules

module "network" {
  source = "./modules/network"

  project_name         = local.project_name
  vpc_cidr             = local.vpc_cidr
  public_subnet_cidrs  = local.public_subnet_cidrs
  private_subnet_cidrs = local.private_subnet_cidrs
}
