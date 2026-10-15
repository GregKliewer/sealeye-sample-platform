locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "logs-and-alarms"
    "juniper:library" = "platform-library"
  })
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/juniper/apps/${local.full_name}"
  retention_in_days = local.upper_stage ? 365 : 7
  tags              = local.tags
}

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${local.full_name}-errors"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = var.error_pattern

  metric_transformation {
    name      = "${local.full_name}-errors"
    namespace = "Juniper/Apps"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${local.full_name}-errors"
  namespace           = "Juniper/Apps"
  metric_name         = "${local.full_name}-errors"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
  tags                = local.tags
}
