output "address" {
  description = "Where the app connects."
  value       = aws_db_instance.db.address
}

output "port" {
  description = "The port the app connects on."
  value       = aws_db_instance.db.port
}

output "database_name" {
  description = "The app's own database, made for it when the platform made the password; none when a password was given by hand."
  value       = local.managed ? local.app_database : null
}

output "database_user" {
  description = "The user the app connects as, signing in with its own identity and no password."
  value       = local.managed ? local.app_user : null
}

output "access_policy_arn" {
  # Only once the user it names exists.
  depends_on  = [aws_lambda_invocation.setup]
  description = "Signs in as the app's user: pass it in the app's policy_arns."
  value       = aws_iam_policy.connect.arn
}

output "log_group" {
  description = "Where the database keeps its own log: errors, refused sign-ins and queries that failed."
  value       = aws_cloudwatch_log_group.db["postgresql"].name
}

output "sign_in_log_group" {
  description = "Where the database keeps each sign-in with an app's own identity that it refused, and why."
  value       = aws_cloudwatch_log_group.db["iam-db-auth-error"].name
}

output "password_secret_arn" {
  description = "Where the platform keeps the master password, when it made it. For restoring by hand, never for the app."
  value       = try(aws_db_instance.db.master_user_secret[0].secret_arn, null)
}
