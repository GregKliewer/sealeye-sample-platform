output "url" {
  description = "The API's address."
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "role_name" {
  description = "The function's role, to grant it what it reads and writes."
  value       = aws_iam_role.fn.name
}

output "access_log_group" {
  description = "Where the front door keeps its record of each request, so it can be read back to the developer beside the app's own lines."
  value       = aws_cloudwatch_log_group.door.name
}

output "log_group" {
  description = "Where everything the app prints is kept, so the front door can read it back to the developer."
  value       = aws_cloudwatch_log_group.fn.name
}
