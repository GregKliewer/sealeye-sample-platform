output "address" {
  description = "Where the app connects."
  value       = aws_db_instance.db.address
}

output "port" {
  description = "The port the app connects on."
  value       = aws_db_instance.db.port
}

output "database_name" {
  description = "The app's own database, made for it when the platform made the password."
  value       = local.app_database
}

output "database_user" {
  description = "The user the app connects as, signing in with its own identity and no password."
  value       = local.app_user
}

output "access_policy_arn" {
  description = "Signs in as the app's user: pass it in the app's policy_arns."
  value       = aws_iam_policy.connect.arn
}

output "password_secret_arn" {
  description = "Where the platform keeps the master password, when it made it. For restoring by hand, never for the app."
  value       = try(aws_db_instance.db.master_user_secret[0].secret_arn, null)
}
