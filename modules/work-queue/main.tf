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
