output "table_name" {
  description = "The table."
  value       = aws_dynamodb_table.table.name
}

output "table_arn" {
  description = "The table, to grant the app access."
  value       = aws_dynamodb_table.table.arn
}

output "access_policy_arn" {
  description = "Reads and writes the table: pass it in the app's policy_arns."
  value       = aws_iam_policy.read_write.arn
}

output "read_only_policy_arn" {
  description = "Reads the table only: pass it in the app's policy_arns."
  value       = aws_iam_policy.read_only.arn
}
