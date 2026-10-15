output "url" {
  description = "The API's address."
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "role_name" {
  description = "The function's role, to grant it what it reads and writes."
  value       = aws_iam_role.fn.name
}
