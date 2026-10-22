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

  # The database and the user the app signs in as, named after the app, as postgres
  # names them. The user signs in with its own identity (see the README), never with a
  # password.
  app_database = replace(var.name, "-", "_")
  app_user     = "${replace(var.name, "-", "_")}_app"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_db_subnet_group" "stage" {
  name = var.subnet_group_name
}

resource "aws_rds_cluster" "db" {
  cluster_identifier                  = local.full_name
  engine                              = "aurora-postgresql"
  engine_version                      = "16.4"
  master_username                     = "app"
  manage_master_user_password         = true
  db_subnet_group_name                = var.subnet_group_name
  vpc_security_group_ids              = concat(var.security_group_ids, [aws_security_group.setup.id])
  iam_database_authentication_enabled = true
  storage_encrypted                   = true
  backup_retention_period             = local.upper_stage ? 35 : 7
  deletion_protection                 = local.upper_stage
  # Below staging a change (signing in, the size) applies at once, not at the next
  # maintenance window.
  apply_immediately         = !local.upper_stage
  skip_final_snapshot       = !local.upper_stage
  final_snapshot_identifier = local.upper_stage ? "${local.full_name}-final" : null
  tags                      = local.tags
}

resource "aws_rds_cluster_instance" "db" {
  count              = local.upper_stage ? 2 : 1
  identifier         = "${local.full_name}-${count.index}"
  cluster_identifier = aws_rds_cluster.db.id
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.db.engine
  engine_version     = aws_rds_cluster.db.engine_version
  apply_immediately  = !local.upper_stage
  tags               = local.tags
}

# What the app needs to sign in: the right to connect as its user with its own
# identity, on this cluster. The app's module attaches it to the app's role (its
# policy_arns input). Nothing outside the library writes a grant.
data "aws_iam_policy_document" "connect" {
  statement {
    actions   = ["rds-db:connect"]
    resources = ["arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_rds_cluster.db.cluster_resource_id}/${local.app_user}"]
  }
}

resource "aws_iam_policy" "connect" {
  name   = "${local.full_name}-db-connect"
  policy = data.aws_iam_policy_document.connect.json
  tags   = local.tags
}

# The one-time setup: a function in the private network that signs in as the master
# user once, when the database is made, and makes the app's database and user. It is
# the only thing that ever reads the master password; the app never does.
#
# It connects from a group of its own, which the database admits, so the platform's
# groups are never changed by an app's environment.
resource "aws_security_group" "setup" {
  name        = "${local.full_name}-db-setup"
  description = "The one-time database setup, which the database admits"
  vpc_id      = data.aws_db_subnet_group.stage.vpc_id
  tags        = local.tags

  # The platform can hold the setup function's network interface for a while after the
  # function is gone; the group waits for it rather than failing the tear-down.
  timeouts {
    delete = "40m"
  }
}

resource "aws_vpc_security_group_ingress_rule" "setup" {
  security_group_id            = aws_security_group.setup.id
  referenced_security_group_id = aws_security_group.setup.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  tags                         = local.tags
}

resource "aws_vpc_security_group_egress_rule" "setup" {
  security_group_id = aws_security_group.setup.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = local.tags
}

data "aws_iam_policy_document" "setup_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "setup" {
  name                 = "${local.full_name}-db-setup"
  assume_role_policy   = data.aws_iam_policy_document.setup_assume.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "setup_network" {
  role       = aws_iam_role.setup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "setup_secret" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [aws_rds_cluster.db.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "setup_secret" {
  name   = "read-master-password"
  role   = aws_iam_role.setup.id
  policy = data.aws_iam_policy_document.setup_secret.json
}

resource "aws_cloudwatch_log_group" "setup" {
  name              = "/aws/lambda/${local.full_name}-db-setup"
  retention_in_days = local.upper_stage ? 365 : 7
  tags              = local.tags
}

resource "aws_lambda_function" "setup" {
  function_name    = "${local.full_name}-db-setup"
  role             = aws_iam_role.setup.arn
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  filename         = "${path.module}/setup/setup.zip"
  source_code_hash = filebase64sha256("${path.module}/setup/setup.zip")
  timeout          = 60
  tags             = local.tags

  vpc_config {
    subnet_ids         = data.aws_db_subnet_group.stage.subnet_ids
    security_group_ids = [aws_security_group.setup.id]
  }

  depends_on = [aws_cloudwatch_log_group.setup, aws_iam_role_policy_attachment.setup_network]
}

# Runs once, when the database is made (or moves), and again only if its input changes.
# A failure fails the apply, so a database never stands without its app user.
resource "aws_lambda_invocation" "setup" {
  function_name = aws_lambda_function.setup.function_name

  input = jsonencode({
    secret_arn = aws_rds_cluster.db.master_user_secret[0].secret_arn
    host       = aws_rds_cluster.db.endpoint
    port       = aws_rds_cluster.db.port
    database   = local.app_database
    user       = local.app_user
  })

  # It needs its group's rules in place before it runs: the way to the secrets endpoint
  # and its admission to the database.
  depends_on = [aws_iam_role_policy.setup_secret, aws_vpc_security_group_ingress_rule.setup, aws_vpc_security_group_egress_rule.setup, aws_rds_cluster_instance.db]
}
