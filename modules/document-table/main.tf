locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "document-table"
    "juniper:library" = "platform-library"
  })
}

resource "aws_dynamodb_table" "table" {
  name                        = local.full_name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = var.key
  deletion_protection_enabled = local.upper_stage
  tags                        = local.tags

  attribute {
    name = var.key
    type = "S"
  }

  point_in_time_recovery {
    enabled = local.upper_stage
  }

  server_side_encryption {
    enabled = true
  }
}
