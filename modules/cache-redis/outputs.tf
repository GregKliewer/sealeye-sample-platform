output "address" {
  description = "Where the app connects."
  value       = aws_elasticache_replication_group.cache.primary_endpoint_address
}
