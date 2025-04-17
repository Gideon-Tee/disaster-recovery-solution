provider "aws" {
  region = "eu-west-1"
  alias = "primary"
}

# Primary region configuration

# Primary vpc and networking
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


# Primary region compute resources
module "primary_compute" {
  source       = "../../modules/compute"
  environment  = var.environment
  vpc_id       = module.primary_network.vpc_id            # From networking module
  subnet_ids   = module.primary_network.public_subnet_ids  # Private subnets
  instance_type = "t2.micro"  # Override default (optional)
  key_name      =   var.key_name
}
