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

# What an app needs to use the table, as policies the app's module attaches to the app's
# role (its policy_arns input). Nothing outside the library writes a grant.
data "aws_iam_policy_document" "read_write" {
  statement {
    actions = [
      "dynamodb:GetItem", "dynamodb:BatchGetItem", "dynamodb:Query", "dynamodb:Scan",
      "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem", "dynamodb:ConditionCheckItem", "dynamodb:DescribeTable",
    ]
    resources = [aws_dynamodb_table.table.arn, "${aws_dynamodb_table.table.arn}/index/*"]
  }
}

data "aws_iam_policy_document" "read_only" {
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:BatchGetItem", "dynamodb:Query", "dynamodb:Scan", "dynamodb:DescribeTable"]
    resources = [aws_dynamodb_table.table.arn, "${aws_dynamodb_table.table.arn}/index/*"]
  }
}

resource "aws_iam_policy" "read_write" {
  name   = "${local.full_name}-table-read-write"
  policy = data.aws_iam_policy_document.read_write.json
  tags   = local.tags
}

resource "aws_iam_policy" "read_only" {
  name   = "${local.full_name}-table-read-only"
  policy = data.aws_iam_policy_document.read_only.json
  tags   = local.tags
}
