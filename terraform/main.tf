# main.tf - Connect the root configuration to infrastructure modules

# References:
# Terraform modules

module "network" {
  source = "./modules/network"

  project_name = local.project_name
  vpc_cidr     = local.vpc_cidr
}
