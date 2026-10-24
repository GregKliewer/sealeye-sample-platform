output "plan_id" {
  description = "The backup plan, for the change review's record."
  value       = aws_backup_plan.app.id
}

output "keep_days" {
  description = "How long each day's copy is kept at this stage."
  value       = local.keep_days
}
