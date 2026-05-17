module "vpc" {
  source           = "./modules/vpc"
  vpc_cidr         = var.vpc_cidr
  project_name     = var.project_name
  eks_cluster_name = var.eks_cluster_name
}

module "eks" {
  source             = "./modules/eks"
  project_name       = var.project_name
  eks_cluster_name   = var.eks_cluster_name
  eks_version        = var.eks_version
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}