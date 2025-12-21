# Application Load Balancer (ALB) Module

This module creates an Application Load Balancer with target groups, listeners, and optional access logging.

## Purpose

Provides load balancing, SSL termination, and high availability for web applications. Automatically distributes traffic across multiple targets and performs health checks.

## Resources Created

- **Application Load Balancer**: Layer 7 load balancer
- **Target Group**: Group of targets (EC2 instances)
- **Target Group Attachments**: Associates targets with the target group
- **HTTP Listener**: Port 80 listener (redirects to HTTPS if cert provided)
- **HTTPS Listener**: Port 443 listener (conditional on certificate)
- **CloudWatch Log Group**: For ALB metrics (optional)

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `alb_name` | string | required | Name of the ALB |
| `internal` | bool | `false` | Whether the ALB is internal or internet-facing |
| `security_group_ids` | list(string) | required | Security group IDs for the ALB |
| `subnet_ids` | list(string) | required | Subnet IDs for the ALB (minimum 2) |
| `vpc_id` | string | required | VPC ID for the target group |
| `enable_deletion_protection` | bool | `false` | Prevent accidental deletion |
| `enable_http2` | bool | `true` | Enable HTTP/2 protocol |
| `enable_cross_zone_load_balancing` | bool | `true` | Distribute traffic across AZs |
| `access_logs_bucket` | string | `null` | S3 bucket name for access logs |
| `access_logs_prefix` | string | `alb-logs` | S3 prefix for access logs |
| `target_group_name` | string | required | Name of the target group |
| `target_port` | number | `80` | Port targets listen on |
| `target_protocol` | string | `HTTP` | Protocol for target communication |
| `target_ids` | list(string) | `[]` | List of instance IDs to attach |
| `health_check_healthy_threshold` | number | `2` | Consecutive successes for healthy |
| `health_check_unhealthy_threshold` | number | `2` | Consecutive failures for unhealthy |
| `health_check_timeout` | number | `5` | Health check timeout in seconds |
| `health_check_interval` | number | `30` | Health check interval in seconds |
| `health_check_path` | string | `/` | Health check URL path |
| `health_check_protocol` | string | `HTTP` | Health check protocol |
| `health_check_matcher` | string | `200` | HTTP codes indicating health |
| `deregistration_delay` | number | `300` | Drain time before deregistering |
| `certificate_arn` | string | `null` | ARN of SSL certificate |
| `ssl_policy` | string | `ELBSecurityPolicy-TLS13-1-2-2021-06` | SSL security policy |
| `enable_cloudwatch_logs` | bool | `true` | Create CloudWatch log group |
| `log_retention_days` | number | `7` | Log retention period |
| `tags` | map(string) | `{}` | Tags for all resources |

## Outputs

| Output | Description |
|--------|-------------|
| `alb_id` | ALB ID |
| `alb_arn` | ALB ARN |
| `alb_dns_name` | ALB DNS name |
| `alb_zone_id` | Route53 zone ID for the ALB |
| `target_group_arn` | Target group ARN |
| `http_listener_arn` | HTTP listener ARN |
| `https_listener_arn` | HTTPS listener ARN (if created) |
| `cloudwatch_log_group_name` | CloudWatch log group name |

## Usage Example

```hcl
module "alb" {
  source = "./modules/alb"

  alb_name           = "production-alb"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [aws_security_group.alb.id]
  target_group_name  = "web-servers"
  target_ids         = [module.web_server.instance_id]
  certificate_arn    = module.certificate.certificate_arn
  access_logs_bucket = module.s3_logs.bucket_id
  
  # Health check configuration
  health_check_path     = "/health"
  health_check_interval = 15
  health_check_timeout  = 5
  
  tags = {
    Environment = "production"
  }
}
```

## Best Practices

1. **Multi-AZ**: Deploy in at least 2 availability zones
2. **Health Checks**: Use a dedicated health check endpoint
3. **SSL/TLS**: Always use the latest TLS policy
4. **Access Logs**: Enable for troubleshooting and compliance
5. **Deregistration Delay**: Set based on longest request time
6. **Connection Draining**: Allow graceful shutdown of targets
7. **Security Groups**: Only allow traffic from expected sources
