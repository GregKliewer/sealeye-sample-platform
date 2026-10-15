locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "postgres"
    "juniper:library" = "platform-library"
  })
}

resource "aws_db_instance" "db" {
  identifier                  = local.full_name
  engine                      = "postgres"
  engine_version              = "16"
  instance_class              = var.instance_class
  allocated_storage           = 20
  db_subnet_group_name        = var.subnet_group_name
  vpc_security_group_ids      = var.security_group_ids
  username                    = "app"
  manage_master_user_password = var.master_password == null ? true : null
  password                    = var.master_password
  storage_encrypted           = true
  backup_retention_period     = 1
  deletion_protection         = false
  skip_final_snapshot         = true
  tags                        = local.tags
}
