output "certificate_arn" {
  description = "The certificate, once it is validated."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "url" {
  description = "The app's address at its own name."
  value       = "https://${var.domain_name}"
}
