locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "work-queue"
    "juniper:library" = "platform-library"
  })
}

resource "aws_sqs_queue" "failed" {
  name                      = "${local.full_name}-failed"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
  tags                      = local.tags
}

resource "aws_sqs_queue" "work" {
  name                      = local.full_name
  message_retention_seconds = local.upper_stage ? 1209600 : 345600
  sqs_managed_sse_enabled   = true
  tags                      = local.tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.failed.arn
    maxReceiveCount     = var.max_receives
  })
}

# What an app needs to use the queue, as policies the app's module attaches to the app's
# role (its policy_arns input).
data "aws_iam_policy_document" "send_receive" {
  statement {
    actions = [
      "sqs:SendMessage", "sqs:ReceiveMessage", "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility", "sqs:GetQueueAttributes", "sqs:GetQueueUrl",
    ]
    resources = [aws_sqs_queue.work.arn]
  }
}

data "aws_iam_policy_document" "send_only" {
  statement {
    actions   = ["sqs:SendMessage", "sqs:GetQueueAttributes", "sqs:GetQueueUrl"]
    resources = [aws_sqs_queue.work.arn]
  }
}

resource "aws_iam_policy" "send_receive" {
  name   = "${local.full_name}-queue-send-receive"
  policy = data.aws_iam_policy_document.send_receive.json
  tags   = local.tags
}

resource "aws_iam_policy" "send_only" {
  name   = "${local.full_name}-queue-send"
  policy = data.aws_iam_policy_document.send_only.json
  tags   = local.tags
}
