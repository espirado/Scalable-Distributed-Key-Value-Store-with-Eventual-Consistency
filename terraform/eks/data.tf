data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

# Use the local cluster name instead of module reference
locals {
  cluster_name = "${var.project}-${var.environment}-eks"
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = local.cluster_name
}