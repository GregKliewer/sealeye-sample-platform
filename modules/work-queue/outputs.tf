output "queue_url" {
  description = "Where the app sends and reads work."
  value       = aws_sqs_queue.work.url
}

output "failed_queue_url" {
  description = "Where failed work waits to be looked at."
  value       = aws_sqs_queue.failed.url
}

output "access_policy_arn" {
  description = "Sends work and takes it off the queue: pass it in the app's policy_arns."
  value       = aws_iam_policy.send_receive.arn
}

output "send_only_policy_arn" {
  description = "Sends work only: pass it in the app's policy_arns."
  value       = aws_iam_policy.send_only.arn
}
