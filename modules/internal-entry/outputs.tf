output "address" {
  description = "The internal address other apps call."
  value       = aws_lb.entry.dns_name
}

output "target_group_arn" {
  description = "Register the service's tasks here."
  value       = aws_lb_target_group.app.arn
}
