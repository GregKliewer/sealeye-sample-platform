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

  # The database and the user the app signs in as, named after the app. The user signs
  # in with its own identity (see the README), never with a password.
  app_database = replace(var.name, "-", "_")
  app_user     = "${replace(var.name, "-", "_")}_app"

  # The platform makes and keeps the master password unless one is given by hand. Only
  # then can the one-time setup below read it to make the app's user.
  managed = nonsensitive(var.master_password == null)
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_db_subnet_group" "stage" {
  name = var.subnet_group_name
}

resource "aws_db_instance" "db" {
  identifier                          = local.full_name
  engine                              = "postgres"
  engine_version                      = "16"
  instance_class                      = var.instance_class
  allocated_storage                   = 20
  db_subnet_group_name                = var.subnet_group_name
  vpc_security_group_ids              = concat(var.security_group_ids, [aws_security_group.setup.id])
  username                            = "app"
  manage_master_user_password         = var.master_password == null ? true : null
  password                            = var.master_password
  iam_database_authentication_enabled = true
  storage_encrypted                   = true
  backup_retention_period             = 1
  deletion_protection                 = false
  # Below staging a change (the size, signing in) applies at once, not at the next
  # maintenance window.
  apply_immediately   = !local.upper_stage
  skip_final_snapshot = true
  tags                = local.tags
}

# What the app needs to sign in: the right to connect as its user with its own
# identity. The app's module attaches it to the app's role (its policy_arns input).
# Nothing outside the library writes a grant.
data "aws_iam_policy_document" "connect" {
  statement {
    actions   = ["rds-db:connect"]
    resources = ["arn:aws:rds-db:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.db.resource_id}/${local.app_user}"]
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
  count                = local.managed ? 1 : 0
  name                 = "${local.full_name}-db-setup"
  assume_role_policy   = data.aws_iam_policy_document.setup_assume.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "setup_network" {
  count      = local.managed ? 1 : 0
  role       = aws_iam_role.setup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy_document" "setup_secret" {
  count = local.managed ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [aws_db_instance.db.master_user_secret[0].secret_arn]
  }
}

resource "aws_iam_role_policy" "setup_secret" {
  count  = local.managed ? 1 : 0
  name   = "read-master-password"
  role   = aws_iam_role.setup[0].id
  policy = data.aws_iam_policy_document.setup_secret[0].json
}

resource "aws_cloudwatch_log_group" "setup" {
  count             = local.managed ? 1 : 0
  name              = "/aws/lambda/${local.full_name}-db-setup"
  retention_in_days = local.upper_stage ? 365 : 7
  tags              = local.tags
}

resource "aws_lambda_function" "setup" {
  count            = local.managed ? 1 : 0
  function_name    = "${local.full_name}-db-setup"
  role             = aws_iam_role.setup[0].arn
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
  count         = local.managed ? 1 : 0
  function_name = aws_lambda_function.setup[0].function_name

  input = jsonencode({
    secret_arn = aws_db_instance.db.master_user_secret[0].secret_arn
    host       = aws_db_instance.db.address
    port       = aws_db_instance.db.port
    database   = local.app_database
    user       = local.app_user
  })

  # It needs its group's rules in place before it runs: the way to the secrets endpoint
  # and its admission to the database.
  depends_on = [aws_iam_role_policy.setup_secret, aws_vpc_security_group_ingress_rule.setup, aws_vpc_security_group_egress_rule.setup]
}
