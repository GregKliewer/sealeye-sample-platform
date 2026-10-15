output "address" {
  description = "Where the app writes."
  value       = aws_rds_cluster.db.endpoint
}

output "reader_address" {
  description = "Where the app may read."
  value       = aws_rds_cluster.db.reader_endpoint
}

output "password_secret_arn" {
  description = "Where the platform keeps the password."
  value       = aws_rds_cluster.db.master_user_secret[0].secret_arn
}
