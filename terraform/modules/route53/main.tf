resource "aws_route53_zone" "this" {
  count = var.create_zone ? 1 : 0

  name          = var.domain_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name = var.domain_name
    }
  )
}

data "aws_route53_zone" "existing" {
  count = var.create_zone ? 0 : 1

  name         = var.domain_name
  private_zone = false
}

locals {
  zone_id = var.create_zone ? aws_route53_zone.this[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

resource "aws_route53_record" "validation" {
  for_each = var.certificate_validation_records

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60

  allow_overwrite = true
}

resource "aws_route53_record" "alb_alias" {
  count = var.alb_dns_name != null ? 1 : 0

  zone_id = local.zone_id
  name    = var.alb_record_name != "" ? var.alb_record_name : var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.alb_evaluate_target_health
  }
}

resource "aws_route53_record" "cloudfront_alias" {
  count = var.cloudfront_domain_name != null ? 1 : 0

  zone_id = local.zone_id
  name    = var.cloudfront_record_name != "" ? var.cloudfront_record_name : var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "additional_records" {
  for_each = var.additional_records

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = lookup(each.value, "ttl", 300)
  records = each.value.records
}
