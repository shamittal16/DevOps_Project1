# S3 Logs Bucket Module

This module creates an S3 bucket specifically configured for storing access logs from ALB and CloudFront with appropriate permissions and lifecycle policies.

## Purpose

Provides a centralized, secure location for storing and managing access logs from AWS services with automatic lifecycle management to control costs.

## Resources Created

- **S3 Bucket**: Storage for access logs
- **Bucket Ownership Controls**: Manage object ownership
- **Bucket ACL**: Log delivery permissions
- **Bucket Versioning**: Optional versioning
- **Server-Side Encryption**: AES-256 encryption
- **Lifecycle Configuration**: Automatic log expiration and transitions
- **Public Access Block**: Prevent public access
- **Bucket Policy**: Service-specific access permissions

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bucket_name` | string | required | Name of the S3 bucket |
| `force_destroy` | bool | `false` | Allow deletion when containing objects |
| `enable_versioning` | bool | `false` | Enable object versioning |
| `lifecycle_rules_enabled` | bool | `true` | Enable lifecycle policies |
| `log_expiration_days` | number | `90` | Days before logs expire |
| `noncurrent_version_expiration_days` | number | `30` | Expire old versions after days |
| `transition_to_ia_days` | number | `30` | Days before transitioning to IA storage |
| `transition_to_glacier_days` | number | `60` | Days before transitioning to Glacier |
| `alb_log_delivery_principal` | string | required | AWS principal ARN for ALB logs (region-specific) |
| `enable_cloudfront_logs` | bool | `false` | Enable CloudFront log permissions |
| `cloudfront_distribution_arn` | string | `null` | CloudFront distribution ARN |
| `tags` | map(string) | `{}` | Tags for the bucket |

## ALB Log Delivery Principals by Region

| Region | Principal ARN |
|--------|---------------|
| us-east-1 | arn:aws:iam::127311923021:root |
| us-east-2 | arn:aws:iam::033677994240:root |
| us-west-1 | arn:aws:iam::027434742980:root |
| us-west-2 | arn:aws:iam::797873946194:root |
| ap-southeast-1 | arn:aws:iam::114774131450:root |
| ap-southeast-2 | arn:aws:iam::783225319266:root |
| ap-northeast-1 | arn:aws:iam::582318560864:root |
| eu-west-1 | arn:aws:iam::156460612806:root |
| eu-central-1 | arn:aws:iam::054676820928:root |

[Full list](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html)

## Outputs

| Output | Description |
|--------|-------------|
| `bucket_id` | S3 bucket name/ID |
| `bucket_arn` | Bucket ARN |
| `bucket_domain_name` | Bucket domain name |
| `bucket_regional_domain_name` | Regional domain name |

## Usage Example

```hcl
module "s3_logs" {
  source = "./modules/s3_logs"

  bucket_name                 = "my-app-logs-${data.aws_caller_identity.current.account_id}"
  alb_log_delivery_principal  = "arn:aws:iam::783225319266:root"  # ap-southeast-2
  enable_cloudfront_logs      = true
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
  
  # Lifecycle management
  log_expiration_days         = 90
  transition_to_ia_days       = 30
  transition_to_glacier_days  = 60
  
  tags = {
    Environment = "production"
    Purpose     = "Access Logs"
  }
}

data "aws_caller_identity" "current" {}
```

## Storage Lifecycle

```
Day 0-30:   STANDARD storage (most expensive, instant access)
Day 30-60:  STANDARD_IA (cheaper, infrequent access)
Day 60-90:  GLACIER (cheapest, slow retrieval)
Day 90+:    Deleted (no cost)
```

## Cost Optimization

### Example Costs (us-east-1, approximate)
- **STANDARD**: $0.023/GB/month
- **STANDARD_IA**: $0.0125/GB/month
- **GLACIER**: $0.004/GB/month

For 1TB of logs:
- Month 1: $23 (STANDARD)
- Month 2: $12.50 (IA)
- Month 3: $4 (Glacier)
- Total 3 months: $39.50 vs $69 (all STANDARD)

## Best Practices

1. **Bucket Naming**: Include account ID to ensure global uniqueness
2. **Lifecycle Policies**: Align with compliance requirements
3. **Versioning**: Usually unnecessary for logs (disabled by default)
4. **Encryption**: Always enabled (AES-256)
5. **Public Access**: Always blocked
6. **Force Destroy**: Only enable in dev/test environments
7. **Retention**: Balance compliance needs vs storage costs

## Log Analysis

### Query with Athena

```sql
-- ALB logs
CREATE EXTERNAL TABLE alb_logs (
  type string,
  time string,
  elb string,
  client_ip string,
  -- ... more fields
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
LOCATION 's3://bucket-name/alb-logs/';
```

### Use CloudWatch Insights

Enable ALB to send logs to CloudWatch Logs for real-time querying.

## Troubleshooting

### Logs Not Appearing
1. Verify bucket policy includes correct service principal
2. Check bucket name in ALB/CloudFront configuration
3. Ensure bucket exists before enabling logging
4. Wait 5-10 minutes for first logs

### Access Denied Errors
1. Check bucket policy has correct permissions
2. Verify ALB log delivery principal for your region
3. Ensure bucket ACL allows log-delivery-write

### High Storage Costs
1. Review lifecycle policies
2. Reduce retention period if compliant
3. Enable transitions to cheaper storage classes
4. Consider log sampling for high-traffic sites
