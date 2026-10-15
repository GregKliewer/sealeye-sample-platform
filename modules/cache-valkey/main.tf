locals {
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "cache-valkey"
    "juniper:library" = "platform-library"
  })
}

resource "aws_elasticache_replication_group" "cache" {
  replication_group_id       = substr(local.full_name, 0, 40)
  description                = "Cache for ${local.full_name}"
  engine                     = "valkey"
  engine_version             = "8.0"
  node_type                  = "cache.t4g.small"
  num_cache_clusters         = local.upper_stage ? 2 : 1
  subnet_group_name          = var.subnet_group_name
  security_group_ids         = var.security_group_ids
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  tags                       = local.tags
}
