output "bucket_name" {
  description = "Upload the site's files here."
  value       = aws_s3_bucket.site.bucket
}

output "url" {
  description = "The site's address."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}
