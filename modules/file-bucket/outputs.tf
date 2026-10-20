output "bucket_name" {
  description = "The bucket."
  value       = aws_s3_bucket.files.bucket
}

output "bucket_arn" {
  description = "The bucket, to grant the app access."
  value       = aws_s3_bucket.files.arn
}

output "access_policy_arn" {
  description = "Reads, writes and deletes the bucket's files: pass it in the app's policy_arns."
  value       = aws_iam_policy.read_write.arn
}

output "read_only_policy_arn" {
  description = "Reads the bucket's files only: pass it in the app's policy_arns."
  value       = aws_iam_policy.read_only.arn
}
