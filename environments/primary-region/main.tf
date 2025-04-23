provider "aws" {
  region = "eu-west-1"
  alias  = "primary"
}

provider "aws" {
  region = "us-east-1"
  alias  = "dr"
}
# Primary region configuration

# Primary vpc and networking
module "primary_network" {
  source = "../../modules/networking"
  providers = {
    aws = aws.primary
  }
  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  region               = var.region
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}


module "primary_load_balancer" {
  source             = "../../modules/load-balancing"
  environment        = "primary"
  vpc_id             = module.primary_network.vpc_id
  subnet_ids         = module.primary_network.public_subnet_ids # Public subnets for ALB
  security_group_ids = [module.primary_network.alb_security_group_id]
  dr_security_group_ids = [module.primary_network.dr_alb_security_group_id]
  dr_subnet_ids = module.primary_network.dr_public_subnet_ids
  dr_vpc_id          = module.primary_network.dr_vpc_id
}

# Primary region compute resources
module "primary_compute" {
  source                   = "../../modules/compute"
  environment              = var.environment
  vpc_id                   = module.primary_network.vpc_id            # From networking module
  subnet_ids               = module.primary_network.public_subnet_ids # Public subnets
  instance_type            = "t2.micro"                               # Override default
  key_name                 = var.key_name
  target_group_arns        = [module.primary_load_balancer.target_group_arn]
  iam_instance_profile_arn = module.iam.ec2_instance_profile_arn
  s3_bucket_name           = module.storage.blog_bucket_id
  db_username              = module.primary_db.db_username
  db_password              = module.primary_db.db_password
  db_host                  = module.primary_db.primary_db_endpoint
  db_name                  = var.db_name
  region                   = var.region
  aws_access_key           = var.aws_access_key
  aws_secret_key           = var.aws_secret_key
  load_balancer_sg_id      = module.primary_load_balancer.load_balancer_sg_id
  dr-subnet_ids = module.primary_network.dr_public_subnet_ids
  dr_vpc_id                = module.primary_network.dr_vpc_id
  dr_load_balancer_sg_id   = module.primary_load_balancer.dr_load_balancer_sg_id
  dr-target_group_arns = [module.primary_load_balancer.dr_target_group_arn]
}

# Primary RDS instance
module "primary_db" {
  source             = "../../modules/database"
  environment        = "primary"
  vpc_id             = module.primary_network.vpc_id
  private_subnet_ids = module.primary_network.private_subnet_ids
  database_engine    = "mysql"
  db_name            = var.db_name

  dr_private_subnet_ids = module.primary_network.dr_private_subnet_ids
  dr_vpc_id             = module.primary_network.dr_vpc_id
}


module "storage" {
  source          = "../../modules/storage"
  environment     = "primary"
  ec2_role_arn    = module.iam.ec2_role_arn
  dr_ec2_role_arn = module.iam.dr_ec2_role_arn
}

module "iam" {
  source         = "../../modules/iam"
  environment    = "primary"
  s3_bucket_name = module.storage.blog_bucket_id
}

module "ssm_ami_automation" {
  source = "../../modules/dr-automation"

  primary_instance_id = module.primary_compute.primary_instance_id
}