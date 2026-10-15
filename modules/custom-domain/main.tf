locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "custom-domain"
    "juniper:library" = "platform-library"
  })
}

resource "aws_acm_certificate" "this" {
  domain_name       = var.domain_name
  validation_method = "DNS"
  tags              = local.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for o in aws_acm_certificate.this.domain_validation_options : o.domain_name => o
  }

  zone_id = var.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

resource "aws_route53_record" "name" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.target_domain_name
    zone_id                = var.target_zone_id
    evaluate_target_health = false
  }
}
