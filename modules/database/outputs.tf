output "rds_endpoints" {
  value = { for k, v in aws_db_instance.services : k => v.address }
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.analytics.name
}
