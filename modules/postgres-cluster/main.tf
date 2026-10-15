locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "postgres-cluster"
    "juniper:library" = "platform-library"
  })
}

resource "aws_rds_cluster" "db" {
  cluster_identifier          = local.full_name
  engine                      = "aurora-postgresql"
  engine_version              = "16.4"
  master_username             = "app"
  manage_master_user_password = true
  db_subnet_group_name        = var.subnet_group_name
  vpc_security_group_ids      = var.security_group_ids
  storage_encrypted           = true
  backup_retention_period     = local.upper_stage ? 35 : 7
  deletion_protection         = local.upper_stage
  skip_final_snapshot         = !local.upper_stage
  final_snapshot_identifier   = local.upper_stage ? "${local.full_name}-final" : null
  tags                        = local.tags
}

resource "aws_rds_cluster_instance" "db" {
  count              = local.upper_stage ? 2 : 1
  identifier         = "${local.full_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.db.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.db.engine
  engine_version     = aws_rds_cluster.db.engine_version
  tags               = local.tags
}
