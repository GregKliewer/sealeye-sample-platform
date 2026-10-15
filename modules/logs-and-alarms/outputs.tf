output "log_group" {
  description = "Where the app's logs go."
  value       = aws_cloudwatch_log_group.app.name
}

output "alarm_name" {
  description = "The alarm on the app's errors."
  value       = aws_cloudwatch_metric_alarm.errors.alarm_name
}
