output "zone_id" {
  description = "Route53 zone ID"
  value       = local.zone_id
}

output "zone_name" {
  description = "Route53 zone name"
  value       = var.domain_name
}

output "name_servers" {
  description = "Name servers for the zone (if created)"
  value       = var.create_zone ? aws_route53_zone.this[0].name_servers : null
}

output "validation_record_fqdns" {
  description = "FQDNs of validation records"
  value       = [for record in aws_route53_record.validation : record.fqdn]
}

output "alb_record_fqdn" {
  description = "FQDN of the ALB alias record"
  value       = length(aws_route53_record.alb_alias) > 0 ? aws_route53_record.alb_alias[0].fqdn : null
}

output "cloudfront_record_fqdn" {
  description = "FQDN of the CloudFront alias record"
  value       = length(aws_route53_record.cloudfront_alias) > 0 ? aws_route53_record.cloudfront_alias[0].fqdn : null
}
