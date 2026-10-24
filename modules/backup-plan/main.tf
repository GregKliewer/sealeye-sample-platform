locals {
  # From staging up, an environment is held to production's rules (see the README).
  # prod keeps its copies for a year; every other stage for five weeks.
  keep_days = var.stage == "prod" ? 365 : 35
  full_name = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "backup-plan"
    "juniper:library" = "platform-library"
  })
}

# A copy of everything the app keeps, once a day, into the stage's vault.
resource "aws_backup_plan" "app" {
  name = "${local.full_name}-backups"

  rule {
    rule_name         = "daily"
    target_vault_name = var.vault_name
    # 05:00 UTC, after the evening's batch work and before the business day.
    schedule = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = local.keep_days
    }
  }

  tags = local.tags
}

# What it copies: every resource the library's modules made for this app at this stage,
# found by the labels every module sets. An app never lists its resources here, so a
# database added later is copied without a change to this module.
resource "aws_backup_selection" "app" {
  name         = "${local.full_name}-backups"
  plan_id      = aws_backup_plan.app.id
  iam_role_arn = var.backup_role_arn
  resources    = ["*"]

  condition {
    string_equals {
      key   = "aws:ResourceTag/juniper:app"
      value = var.name
    }
    string_equals {
      key   = "aws:ResourceTag/juniper:stage"
      value = var.stage
    }
  }
}
