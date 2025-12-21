# Route53 DNS Module

This module manages Route53 hosted zones and DNS records, including certificate validation records and alias records for AWS resources.

## Purpose

Automates DNS management for your domains, including creation of zones, validation records for ACM certificates, and alias records for load balancers and CloudFront distributions.

## Resources Created

- **Route53 Hosted Zone**: DNS zone for your domain (optional)
- **Certificate Validation Records**: CNAME records for ACM validation
- **ALB Alias Record**: A record pointing to Application Load Balancer
- **CloudFront Alias Record**: A record pointing to CloudFront distribution
- **Additional Records**: Custom DNS records as needed

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `domain_name` | string | required | Domain name for the zone |
| `create_zone` | bool | `false` | Create new zone or use existing |
| `force_destroy` | bool | `false` | Allow destroying zone with records |
| `certificate_validation_records` | map(object) | `{}` | Certificate validation CNAME records |
| `alb_dns_name` | string | `null` | DNS name of the ALB |
| `alb_zone_id` | string | `null` | Zone ID of the ALB |
| `alb_record_name` | string | `""` | Record name for ALB (empty for apex) |
| `alb_evaluate_target_health` | bool | `true` | Evaluate ALB health for DNS |
| `cloudfront_domain_name` | string | `null` | CloudFront distribution domain |
| `cloudfront_zone_id` | string | `Z2FDTNDATAQYW2` | CloudFront zone ID (constant) |
| `cloudfront_record_name` | string | `""` | Record name for CloudFront |
| `additional_records` | map(object) | `{}` | Custom DNS records |
| `tags` | map(string) | `{}` | Tags for resources |

### Certificate Validation Record Structure

```hcl
certificate_validation_records = {
  "example.com" = {
    name   = "_abc123.example.com"
    type   = "CNAME"
    record = "_def456.acm-validations.aws"
  }
}
```

### Additional Record Structure

```hcl
additional_records = {
  "mail" = {
    name    = "mail.example.com"
    type    = "A"
    records = ["192.0.2.1"]
    ttl     = 300  # optional
  }
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `zone_id` | Route53 zone ID |
| `zone_name` | Zone domain name |
| `name_servers` | Name servers (if zone created) |
| `validation_record_fqdns` | FQDNs of validation records |
| `alb_record_fqdn` | FQDN of ALB record |
| `cloudfront_record_fqdn` | FQDN of CloudFront record |

## Usage Example

### Create New Zone

```hcl
module "route53" {
  source = "./modules/route53"

  domain_name  = "example.com"
  create_zone  = true
  
  # ALB record
  alb_dns_name    = module.alb.alb_dns_name
  alb_zone_id     = module.alb.alb_zone_id
  alb_record_name = "alb.example.com"
  
  # CloudFront record (apex domain)
  cloudfront_domain_name = module.cloudfront.distribution_domain_name
  cloudfront_record_name = ""  # empty for apex
  
  # Certificate validation
  certificate_validation_records = {
    for dvo in module.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  
  # Additional records
  additional_records = {
    "www" = {
      name    = "www.example.com"
      type    = "CNAME"
      records = ["example.com"]
    }
  }
  
  tags = {
    Environment = "production"
  }
}
```

### Use Existing Zone

```hcl
module "route53" {
  source = "./modules/route53"

  domain_name = "example.com"
  create_zone = false  # Use existing zone
  
  # Rest of configuration...
}
```

## Post-Deployment Steps

If you created a new hosted zone, you need to:

1. **Get the name servers**:
   ```bash
   terraform output route53_name_servers
   ```

2. **Update your domain registrar** with these name servers

3. **Wait for propagation** (can take up to 48 hours, usually much faster)

## Best Practices

1. **Zone Management**: Use existing zones when possible to avoid disruption
2. **Alias Records**: Use for AWS resources (ALB, CloudFront) - they're free
3. **TTL Values**: Lower TTL (300s) during changes, higher (3600s) for stability
4. **Health Checks**: Enable for ALB alias records
5. **Apex Domain**: Use empty string for record name to create apex record
6. **Validation**: Allow 5-30 minutes for certificate validation
7. **Force Destroy**: Only enable in development environments

## Common Patterns

### Apex and WWW

```hcl
# Apex points to CloudFront
cloudfront_record_name = ""

# WWW CNAME to apex
additional_records = {
  "www" = {
    name    = "www.example.com"
    type    = "CNAME"
    records = ["example.com"]
  }
}
```

### Multiple Subdomains

```hcl
alb_record_name = "api.example.com"

additional_records = {
  "app" = {
    name    = "app.example.com"
    type    = "CNAME"
    records = ["cloudfront.net"]
  }
  "admin" = {
    name    = "admin.example.com"
    type    = "A"
    records = ["192.0.2.1"]
  }
}
```
