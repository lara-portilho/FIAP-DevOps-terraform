variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix used in all resource names"
  type        = string
  default     = "togglemaster"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "production"
}

# ── EKS ────────────────────────────────────────────────────────────────────

# m7i-flex.large (2 vCPU, 8 GB, ate 29 pods/no) e "Free Tier eligible" -- contas no
# plano gratuito da AWS nao podem usar t3.medium. t3.small (11 pods/no, 2 GB) nao
# comporta a stack de observabilidade (Prometheus, Grafana, Loki, Alloy) da Fase 4.
variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "m7i-flex.large"
}

variable "eks_node_min" {
  type    = number
  default = 1
}

variable "eks_node_desired" {
  type    = number
  default = 2
}

variable "eks_node_max" {
  type    = number
  default = 2
}

# ── RDS ────────────────────────────────────────────────────────────────────

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_username" {
  description = "Master username for all RDS instances"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password for all RDS instances"
  type        = string
  sensitive   = true
}
