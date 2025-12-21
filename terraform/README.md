# DevOps Infrastructure Project

This Terraform project creates a complete web application infrastructure on AWS with the following components:

## Architecture

```
Internet
   |
   v
CloudFront (CDN) [Optional]
   |
   v
Application Load Balancer (ALB)
   |
   v
EC2 Instance (Ubuntu + Apache)
   |
VPC with Public/Private Subnets
```

## Components

### Core Infrastructure
- **VPC**: Custom VPC with public and private subnets across 2 availability zones
- **EC2 Instance**: Ubuntu 22.04 LTS with Apache web server
- **Application Load Balancer**: HTTP/HTTPS load balancer with SSL termination
- **CloudFront**: Global CDN for content delivery (optional)

### Security & Certificates
- **ACM Certificates**: Managed SSL/TLS certificates for ALB and CloudFront
- **Route53**: DNS management with automatic certificate validation
- **Security Groups**: Least-privilege network access controls
- **IAM Roles**: EC2 instance role for CloudWatch access

### Logging & Monitoring
- **CloudWatch Logs**: 
  - EC2 instance logs (syslog, auth, Apache)
  - ALB access logs
  - CloudFront access logs
- **CloudWatch Metrics**: CPU, memory, disk, and network metrics
- **S3 Access Logs**: ALB and CloudFront access logs stored in S3

## Module Structure

```
terraform/
├── first_ec2.tf           # Main configuration
├── variables.tf           # Input variables
├── outputs.tf             # Output values
├── user_data.sh          # EC2 initialization script
├── modules/
│   ├── vpc/              # VPC module
│   ├── vm/               # EC2 instance module
│   ├── alb/              # Application Load Balancer module
│   ├── certificate/      # ACM certificate module
│   ├── route53/          # DNS management module
│   ├── cloudfront/       # CloudFront CDN module
│   └── s3_logs/          # S3 logging bucket module
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **AWS CLI** configured with credentials
4. **(Optional) Domain Name** registered in Route53 or elsewhere

## Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `ap-southeast-2` | No |
| `domain_name` | Domain name for the application | `""` | No |
| `create_route53_zone` | Create new Route53 zone | `false` | No |
| `enable_cloudfront` | Enable CloudFront distribution | `true` | No |
| `enable_alb_logging` | Enable ALB access logging | `true` | No |
| `enable_cloudfront_logging` | Enable CloudFront logging | `true` | No |

## Deployment

### Basic Deployment (No Custom Domain)

```bash
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the changes
terraform apply
```

### Deployment with Custom Domain

```bash
cd terraform

# Initialize Terraform
terraform init

# Deploy with domain name
terraform apply -var="domain_name=example.com" -var="create_route53_zone=true"
```

### Deployment Options

#### Disable CloudFront
```bash
terraform apply -var="enable_cloudfront=false"
```

#### Use Existing Route53 Zone
```bash
terraform apply -var="domain_name=example.com" -var="create_route53_zone=false"
```

## Features

### 1. Auto-Scaling Ready
The ALB and target group are configured to support auto-scaling groups (can be added later).

### 2. HTTPS Everywhere
- Automatic SSL certificate provisioning via ACM
- HTTP to HTTPS redirection on ALB
- CloudFront uses HTTPS only

### 3. Comprehensive Logging
All components send logs to CloudWatch and/or S3:
- **EC2**: System logs, auth logs, Apache logs
- **ALB**: Access logs to S3
- **CloudFront**: Access logs to S3

### 4. Cost Optimized
- S3 lifecycle policies automatically expire old logs
- CloudFront uses PriceClass_100 (cheapest tier)
- t3.micro instance (free tier eligible)

### 5. Security Best Practices
- Encrypted root volumes
- Private subnet for future backend services
- Security groups with minimal required access
- S3 bucket encryption and access controls
- No hardcoded secrets

## Outputs

After deployment, Terraform provides:
- ALB DNS name
- CloudFront distribution URL
- Route53 name servers (if zone created)
- Instance IDs and IPs
- Log bucket name
- Access instructions

## Accessing the Application

### Without Custom Domain
```
http://<alb-dns-name>
```

### With Custom Domain
```
https://example.com          # Via CloudFront
https://alb.example.com      # Directly to ALB
```

## Monitoring

### CloudWatch Logs
View logs in AWS Console:
```
CloudWatch → Logs → Log Groups:
  - /aws/ec2/instance-1
  - /aws/alb/devops-alb
  - /aws/cloudfront/devops-cdn
```

### Access Logs
View in S3 bucket:
```
s3://devops-access-logs-<account-id>/
  ├── alb-logs/
  └── cloudfront-logs/
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Note**: If using a custom domain with Route53, you may need to manually remove some DNS records first.

## Troubleshooting

### Certificate Validation Pending
If certificate validation is stuck:
1. Check Route53 for validation records
2. Ensure domain's name servers point to Route53
3. Wait up to 30 minutes for DNS propagation

### ALB Returns 503
- Check target group health checks
- Verify EC2 instance is running
- Check security group rules allow traffic from ALB

### CloudFront Not Serving Content
- CloudFront deployment can take 15-20 minutes
- Check origin (ALB) is accessible
- Verify certificate is validated

## Security Notes

- All traffic between components uses private IPs within VPC
- Public access only via ALB/CloudFront on ports 80/443
- EC2 instance has no direct internet access for SSH (use Systems Manager Session Manager)
- Secrets should be stored in AWS Secrets Manager (not implemented in basic setup)

## Future Enhancements

Potential additions:
- Auto Scaling Group for EC2 instances
- RDS database in private subnet
- ElastiCache for session management
- WAF rules on CloudFront
- AWS Shield for DDoS protection
- Container deployment (ECS/EKS)
