# ACM Certificate Module

This module creates and validates SSL/TLS certificates using AWS Certificate Manager (ACM) with DNS validation.

## Purpose

Automates SSL/TLS certificate provisioning and renewal for your domains. Certificates are free and automatically renewed by AWS.

## Resources Created

- **ACM Certificate**: SSL/TLS certificate for specified domain(s)
- **Certificate Validation**: DNS-based validation (optional)

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `domain_name` | string | required | Primary domain name for the certificate |
| `subject_alternative_names` | list(string) | `[]` | Additional domain names (e.g., `*.example.com`) |
| `validate_certificate` | bool | `true` | Whether to wait for DNS validation |
| `validation_record_fqdns` | list(string) | `[]` | FQDNs of validation records (required if validating) |
| `validation_timeout` | string | `45m` | How long to wait for validation |
| `tags` | map(string) | `{}` | Tags for the certificate |

## Outputs

| Output | Description |
|--------|-------------|
| `certificate_arn` | ARN of the certificate |
| `certificate_id` | Certificate ID |
| `domain_name` | Primary domain name |
| `domain_validation_options` | Validation record details |
| `validation_record_fqdns` | List of validation record FQDNs |

## Usage Example

### With Validation

```hcl
# First, create the certificate
module "certificate" {
  source = "./modules/certificate"

  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com"]
  validate_certificate      = false  # Don't validate yet
  
  tags = {
    Environment = "production"
  }
}

# Create DNS validation records in Route53
module "route53" {
  source = "./modules/route53"
  
  certificate_validation_records = {
    for dvo in module.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
}

# Then validate the certificate
module "certificate_validation" {
  source = "./modules/certificate"

  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com"]
  validate_certificate      = true
  validation_record_fqdns   = module.route53.validation_record_fqdns
  
  tags = {
    Environment = "production"
  }
}
```

### CloudFront Certificate (us-east-1)

```hcl
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "cloudfront_cert" {
  source = "./modules/certificate"
  
  providers = {
    aws = aws.us_east_1
  }

  domain_name               = "example.com"
  subject_alternative_names = ["*.example.com"]
  
  tags = {
    Purpose = "CloudFront"
  }
}
```

## Important Notes

1. **CloudFront Certificates**: Must be created in `us-east-1` region
2. **DNS Validation**: Requires access to domain's DNS records
3. **Wildcard Certificates**: Use `*.example.com` for all subdomains
4. **Validation Time**: Can take 5-30 minutes for DNS propagation
5. **Auto-Renewal**: AWS automatically renews certificates before expiration

## Best Practices

1. **Use DNS Validation**: Easier than email validation and fully automatable
2. **Wildcard Certs**: Include both apex and wildcard (`example.com` and `*.example.com`)
3. **Separate Certs**: Consider separate certificates for different environments
4. **Region**: Create in the region where it will be used (except CloudFront)
5. **Lifecycle**: Use `create_before_destroy` lifecycle rule
