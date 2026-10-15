locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "cache-redis"
    "juniper:library" = "platform-library"
  })
}

# DEPRECATED (March 2025): kept only for the apps that already use it. See the README.
resource "aws_elasticache_replication_group" "cache" {
  replication_group_id       = substr(local.full_name, 0, 40)
  description                = "Deprecated cache for ${local.full_name}"
  engine                     = "redis"
  engine_version             = "6.2"
  node_type                  = "cache.t4g.small"
  num_cache_clusters         = local.upper_stage ? 2 : 1
  subnet_group_name          = var.subnet_group_name
  security_group_ids         = var.security_group_ids
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
  tags                       = local.tags
}
