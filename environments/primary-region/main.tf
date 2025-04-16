# Primary region configuration

module "primary_network" {
  source = "../../modules/networking"
  providers = {
    aws = aws.primary
  }
  vpc_cidr = var.vpc_cidr
  environment = var.environment
  region = var.region
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}