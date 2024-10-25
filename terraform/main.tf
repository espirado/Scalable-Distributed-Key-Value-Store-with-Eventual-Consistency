module "vpc" {
  source = "./vpc"

  environment        = var.environment
  project_name       = var.project_name
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}

module "security_groups" {
  source = "./security_groups"

  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = var.vpc_cidr
  environment = var.environment
  project     = var.project_name
}

module "nat" {
  source = "./nat"
  
  vpc_id                  = module.vpc.vpc_id
  public_subnet_ids       = module.vpc.public_subnet_ids
  private_route_table_ids = module.vpc.private_route_table_ids
  environment            = var.environment
  project               = var.project_name
  create_per_az_nat     = var.environment == "prod"
  
  depends_on = [module.vpc]
}

module "alb" {
  source = "./alb"

  environment        = var.environment
  project           = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  
  # Fix: Correctly specify security groups
  security_group_ids = [module.security_groups.kvstore_lb_sg_id]
  
  kvstore_port         = var.kvstore_client_port
  create_https_listener = var.create_https_listener
  certificate_arn      = var.certificate_arn
  
  tags = var.default_tags

  depends_on = [module.security_groups]
}

module "eks" {
  source = "./eks"

  environment        = var.environment
  project           = var.project_name
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  cluster_version = "1.28"
  
  node_groups = {
    general = {
      instance_types  = ["t3.medium"]
      disk_size      = 50
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      labels = {
        "role" = "general"
      }
      taints = []
    },
    kvstore = {
      instance_types  = ["t3.large"]
      disk_size      = 100
      desired_size   = 3
      min_size       = 3
      max_size       = 5
      labels = {
        "role" = "kvstore"
      }
      taints = []
    }
  }

  depends_on = [
    module.vpc,
    module.security_groups
  ]
}
module "vpc_flow_logs" {
  source = "./vpc-flow"

  environment     = var.environment
  project        = var.project_name
  vpc_id         = module.vpc.vpc_id
  retention_days = 30
  traffic_type   = "ALL"

  tags = var.default_tags

  depends_on = [module.vpc]
}

module "nacls" {
  source = "./nacls"

  environment        = var.environment
  project           = var.project_name
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  depends_on = [module.vpc]
}

