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


module "primary_load_balancer" {
  source             = "../../modules/load-balancing"
  environment        = "primary"
  vpc_id             = module.primary_network.vpc_id
  subnet_ids         = module.primary_network.public_subnet_ids  # Public subnets for ALB
  security_group_ids = [module.primary_network.alb_security_group_id]
}

# Primary region compute resources
module "primary_compute" {
  source       = "../../modules/compute"
  environment  = var.environment
  vpc_id       = module.primary_network.vpc_id            # From networking module
  subnet_ids   = module.primary_network.public_subnet_ids  # Private subnets
  instance_type = "t2.micro"  # Override default
  key_name      =   var.key_name
  target_group_arns = [module.primary_load_balancer.target_group_arn]
}

