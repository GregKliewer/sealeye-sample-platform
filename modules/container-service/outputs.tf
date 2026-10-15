output "service_name" {
  description = "The running service."
  value       = aws_ecs_service.svc.name
}

output "log_group" {
  description = "Where the service's logs go."
  value       = aws_cloudwatch_log_group.svc.name
}
