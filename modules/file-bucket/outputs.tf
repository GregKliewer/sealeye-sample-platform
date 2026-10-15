output "bucket_name" {
  description = "The bucket."
  value       = aws_s3_bucket.files.bucket
}

output "bucket_arn" {
  description = "The bucket, to grant the app access."
  value       = aws_s3_bucket.files.arn
}
