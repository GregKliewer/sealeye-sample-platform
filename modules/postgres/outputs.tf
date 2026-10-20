output "address" {
  description = "Where the app connects."
  value       = aws_db_instance.db.address
}

output "password_secret_arn" {
  description = "Where the platform keeps the password, when it made it."
  value       = try(aws_db_instance.db.master_user_secret[0].secret_arn, null)
}

output "port" {
  description = "The port the app connects on."
  value       = aws_db_instance.db.port
}

output "database_user" {
  description = "The user the app connects as."
  value       = aws_db_instance.db.username
}
