# CloudFront CDN Module

This module creates a CloudFront distribution for global content delivery with custom domain support and access logging.

## Purpose

Provides a Content Delivery Network (CDN) to cache and serve your content from edge locations worldwide, reducing latency and improving user experience.

## Resources Created

- **CloudFront Distribution**: CDN with custom origin configuration
- **CloudWatch Log Group**: For CloudFront metrics (optional)

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `distribution_name` | string | required | Name for the distribution |
| `enabled` | bool | `true` | Enable the distribution |
| `is_ipv6_enabled` | bool | `true` | Enable IPv6 support |
| `comment` | string | `""` | Distribution comment |
| `default_root_object` | string | `index.html` | Default file to serve |
| `price_class` | string | `PriceClass_100` | Price class (edge location coverage) |
| `aliases` | list(string) | `[]` | Custom domain names (CNAMEs) |
| `origin_domain_name` | string | required | Origin domain (e.g., ALB DNS) |
| `origin_id` | string | `primary` | Unique origin identifier |
| `origin_http_port` | number | `80` | HTTP port for origin |
| `origin_https_port` | number | `443` | HTTPS port for origin |
| `origin_protocol_policy` | string | `https-only` | How to connect to origin |
| `origin_ssl_protocols` | list(string) | `["TLSv1.2"]` | SSL protocols for origin |
| `custom_headers` | list(object) | `[]` | Custom headers to origin |
| `allowed_methods` | list(string) | `["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]` | Allowed HTTP methods |
| `cached_methods` | list(string) | `["GET", "HEAD"]` | Methods to cache |
| `forward_query_string` | bool | `true` | Forward query strings |
| `forward_headers` | list(string) | `["Host"]` | Headers to forward |
| `forward_cookies` | string | `none` | Cookie forwarding (none/whitelist/all) |
| `viewer_protocol_policy` | string | `redirect-to-https` | Viewer protocol policy |
| `min_ttl` | number | `0` | Minimum cache TTL |
| `default_ttl` | number | `3600` | Default cache TTL (1 hour) |
| `max_ttl` | number | `86400` | Maximum cache TTL (24 hours) |
| `compress` | bool | `true` | Auto-compress content |
| `logging_bucket` | string | `null` | S3 bucket for access logs |
| `logging_prefix` | string | `cloudfront-logs/` | S3 prefix for logs |
| `logging_include_cookies` | bool | `false` | Include cookies in logs |
| `geo_restriction_type` | string | `none` | Geo restriction (none/whitelist/blacklist) |
| `geo_restriction_locations` | list(string) | `[]` | Country codes for geo restriction |
| `acm_certificate_arn` | string | `null` | ARN of ACM certificate (us-east-1) |
| `minimum_protocol_version` | string | `TLSv1.2_2021` | Minimum TLS version |
| `enable_cloudwatch_logs` | bool | `true` | Create CloudWatch log group |
| `log_retention_days` | number | `7` | Log retention period |
| `tags` | map(string) | `{}` | Tags for resources |

## Outputs

| Output | Description |
|--------|-------------|
| `distribution_id` | CloudFront distribution ID |
| `distribution_arn` | Distribution ARN |
| `distribution_domain_name` | CloudFront domain name |
| `distribution_hosted_zone_id` | Route53 zone ID (always Z2FDTNDATAQYW2) |
| `distribution_status` | Current distribution status |
| `cloudwatch_log_group_name` | CloudWatch log group name |

## Usage Example

```hcl
module "cloudfront" {
  source = "./modules/cloudfront"

  distribution_name      = "production-cdn"
  origin_domain_name     = module.alb.alb_dns_name
  aliases                = ["example.com", "www.example.com"]
  acm_certificate_arn    = module.certificate.certificate_arn
  logging_bucket         = "${module.s3_logs.bucket_id}.s3.amazonaws.com"
  origin_protocol_policy = "https-only"
  
  # Custom cache behavior
  default_ttl = 7200      # 2 hours
  max_ttl     = 86400     # 24 hours
  compress    = true
  
  # Custom headers
  custom_headers = [
    {
      name  = "X-Custom-Header"
      value = "production"
    }
  ]
  
  tags = {
    Environment = "production"
  }
}
```

## Price Classes

| Class | Regions | Use Case |
|-------|---------|----------|
| `PriceClass_100` | US, Canada, Europe | Lowest cost, limited coverage |
| `PriceClass_200` | Above + Asia, Africa, Middle East | Balanced |
| `PriceClass_All` | All edge locations | Best performance, highest cost |

## Origin Protocol Policies

- `http-only`: Connect to origin via HTTP only
- `https-only`: Connect to origin via HTTPS only (recommended)
- `match-viewer`: Use same protocol as viewer

## Best Practices

1. **Certificate Region**: CloudFront certificates MUST be in us-east-1
2. **HTTPS Only**: Use `redirect-to-https` for viewer protocol
3. **Compression**: Enable automatic compression for faster delivery
4. **Cache TTL**: Balance freshness vs performance
5. **Origin Shield**: Consider for high-traffic sites
6. **Access Logs**: Enable for monitoring and debugging
7. **Custom Headers**: Use to identify CloudFront traffic at origin
8. **Invalidations**: Use sparingly, they cost money after 1000/month

## Common Patterns

### Static Website

```hcl
origin_protocol_policy = "http-only"
default_root_object    = "index.html"
default_ttl            = 86400
cached_methods         = ["GET", "HEAD"]
forward_query_string   = false
```

### Dynamic Application

```hcl
origin_protocol_policy = "https-only"
forward_query_string   = true
forward_cookies        = "all"
default_ttl            = 0      # No caching
min_ttl                = 0
```

### API Gateway

```hcl
allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
cached_methods         = ["GET", "HEAD", "OPTIONS"]
forward_headers        = ["Authorization", "Host"]
forward_cookies        = "all"
```

## Deployment Time

CloudFront distributions take 15-20 minutes to deploy globally. The status will show "InProgress" until complete.

## Troubleshooting

### 502 Bad Gateway
- Check origin is accessible from CloudFront IPs
- Verify SSL certificate on origin
- Ensure security groups allow CloudFront

### Cached Old Content
- Create invalidation: `aws cloudfront create-invalidation --distribution-id XXX --paths "/*"`
- Or wait for TTL to expire

### Certificate Errors
- Ensure certificate is in us-east-1
- Verify certificate includes all aliases
- Check certificate is validated
