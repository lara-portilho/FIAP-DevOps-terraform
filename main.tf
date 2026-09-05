terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  eks_cluster_name = "${var.project_name}-cluster"
}

module "networking" {
  source = "./modules/networking"

  project_name     = var.project_name
  aws_region       = var.aws_region
  eks_cluster_name = local.eks_cluster_name
}

module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  cluster_name       = local.eks_cluster_name
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  node_instance_type = var.eks_node_instance_type
  node_min           = var.eks_node_min
  node_desired       = var.eks_node_desired
  node_max           = var.eks_node_max
}

module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  vpc_cidr_block     = module.networking.vpc_cidr_block
  private_subnet_ids = module.networking.private_subnet_ids
  db_instance_class  = var.db_instance_class
  db_username        = var.db_username
  db_password        = var.db_password
}

module "messaging" {
  source = "./modules/messaging"

  project_name = var.project_name
}

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.aws_region]
    }
  }
}
