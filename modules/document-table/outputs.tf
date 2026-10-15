output "table_name" {
  description = "The table."
  value       = aws_dynamodb_table.table.name
}

output "table_arn" {
  description = "The table, to grant the app access."
  value       = aws_dynamodb_table.table.arn
}
