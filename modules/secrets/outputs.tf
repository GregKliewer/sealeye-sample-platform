output "secret_arns" {
  description = "Each secret, by name, to grant the app access."
  value       = { for k, s in aws_secretsmanager_secret.each : k => s.arn }
}
