variable "project_name" {
  description = "Project prefix used in all resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region, used to build VPC endpoint service names"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster that will use these subnets, for the kubernetes.io/cluster tag"
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}
