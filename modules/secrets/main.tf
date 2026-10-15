locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "secrets"
    "juniper:library" = "platform-library"
  })
}

resource "aws_secretsmanager_secret" "each" {
  for_each                = toset(var.secret_names)
  name                    = "juniper/${local.full_name}/${each.value}"
  recovery_window_in_days = local.upper_stage ? 30 : 0
  tags                    = local.tags
}
