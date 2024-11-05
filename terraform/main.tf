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

module "alb" {
  source = "./alb"

  environment        = var.environment
  project           = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_ids = [module.security_groups.kvstore_lb_sg_id]
  kvstore_port      = var.kvstore_client_port

  # Health check settings
  health_check_path = "/health"
  health_check_interval = 30
  health_check_timeout = 5
  health_check_healthy_threshold = 3
  health_check_unhealthy_threshold = 3

  # Enable deletion protection in production
  enable_deletion_protection = var.environment == "prod"

  tags = var.default_tags

  depends_on = [module.vpc, module.security_groups]
}

module "vpc_endpoints" {
  source = "./vpc_endpoints"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  route_table_ids    = concat(
    [module.vpc.public_route_table_id],
    module.vpc.private_route_table_ids
  )
  security_group_ids = [module.security_groups.kvstore_nodes_sg_id]

  depends_on = [
    module.vpc,
    module.security_groups
  ]
}
module "route53" {
  source = "./route53"

  environment     = var.environment
  project_name    = var.project_name
  domain_name     = var.domain_name
  alb_dns_name    = module.alb.alb_dns_name
  alb_zone_id     = module.alb.alb_zone_id
  vpc_id          = module.vpc.vpc_id
  
  create_private_zone = true
  tags              = var.default_tags

  depends_on = [module.alb, module.vpc]
}

module "cloudwatch" {
  source = "./cloudwatch"

  environment            = var.environment
  project_name           = var.project_name
  alb_arn_suffix        = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  cluster_name          = module.eks.cluster_id

  depends_on = [
    module.alb,
    module.eks
  ]
}


module "storage" {
  source = "./storage"

  environment = var.environment
  project_name = var.project_name
  
  # Override defaults if needed
  backup_retention_days = var.environment == "prod" ? 90 : 30
  log_retention_days = var.environment == "prod" ? 365 : 90
  
  # Force destroy only in non-prod environments
  bucket_force_destroy = var.environment != "prod"

  depends_on = [module.eks]
}

module "logging" {
  source = "./logging"

  environment         = var.environment
  project_name        = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_cluster_name   = module.eks.cluster_id
  eks_cluster_endpoint = module.eks.cluster_endpoint
  domain_name        = var.domain_name

  depends_on = [
    module.vpc,
    module.eks
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
  depends_on = [module.eks]
}

module "metrics" {
  source = "./metrics"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  project_name            = var.project_name
  environment            = var.environment
  retention_days         = var.retention_days
  grafana_admin_password = var.grafana_admin_password

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  cluster_endpoint       = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = data.aws_eks_cluster.cluster.certificate_authority[0].data
  cluster_name          = data.aws_eks_cluster.cluster.name

  depends_on = [
    module.eks,
    module.vpc
  ]
}