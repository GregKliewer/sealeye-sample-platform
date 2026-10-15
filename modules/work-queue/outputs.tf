output "queue_url" {
  description = "Where the app sends and reads work."
  value       = aws_sqs_queue.work.url
}

output "failed_queue_url" {
  description = "Where failed work waits to be looked at."
  value       = aws_sqs_queue.failed.url
}
