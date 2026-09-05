output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repositories" {
  value = module.ecr.repository_urls
}

output "rds_endpoints" {
  value = module.database.rds_endpoints
}

output "redis_endpoint" {
  value = module.database.redis_endpoint
}

output "sqs_queue_url" {
  value = module.messaging.queue_url
}

output "dynamodb_table_name" {
  value = module.database.dynamodb_table_name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
