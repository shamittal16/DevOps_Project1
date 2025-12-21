# Infrastructure Architecture

# Infrastructure Architecture

## Complete Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                           Internet                                │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         │ HTTPS (optional)
                         │
                ┌────────▼──────────┐
                │   CloudFront      │  (Optional CDN)
                │   Distribution    │  - Global edge locations
                │                   │  - Certificate in us-east-1
                │   Logging: S3     │  - Access logs to S3
                └────────┬──────────┘
                         │
                         │ HTTP/HTTPS
                         │
┌──────────────────────────────────────────────────────────────────┐
│                   AWS Region (ap-southeast-2)                     │
│                                                                   │
│              ┌────────▼──────────┐                                │
│              │  Application      │                                │
│              │  Load Balancer    │  - HTTP → HTTPS redirect      │
│              │  (ALB)            │  - SSL Termination            │
│              │                   │  - Health checks              │
│              │  Logging: S3      │  - Access logs to S3          │
│              └────────┬──────────┘                                │
│                       │                                           │
│  ┌────────────────────┼──────────────────────────┐               │
│  │                    │            VPC            │               │
│  │  ┌─────────────────┴───────────────────────┐  │               │
│  │  │        Public Subnets (Multi-AZ)        │  │               │
│  │  │                                          │  │               │
│  │  │    ┌──────────────────────────┐         │  │               │
│  │  │    │ EC2 Instance (t3.micro)  │         │  │               │
│  │  │    │ - Ubuntu 22.04 LTS       │         │  │               │
│  │  │    │ - Apache Web Server      │         │  │               │
│  │  │    │ - CloudWatch Agent       │         │  │               │
│  │  │    │                           │         │  │               │
│  │  │    │ Security Group:           │         │  │               │
│  │  │    │ - Port 80 from VPC        │         │  │               │
│  │  │    │ - Port 22 from VPC        │         │  │               │
│  │  │    └───────────┬──────────────┘         │  │               │
│  │  │                │                         │  │               │
│  │  └────────────────┼─────────────────────────┘  │               │
│  │                   │                            │               │
│  │  ┌────────────────┼──────────────────────┐    │               │
│  │  │                │  Private Subnets     │    │               │
│  │  │                │  (Reserved)          │    │               │
│  │  │                │                      │    │               │
│  │  └────────────────┼──────────────────────┘    │               │
│  │                   │                            │               │
│  └───────────────────┼────────────────────────────┘               │
│                      │                                            │
│                      │  IAM Role                                  │
│                      └──────────────┐                             │
│                                     │                             │
│  ┌──────────────────────────────────▼──────────────┐             │
│  │        CloudWatch Logs & Metrics                │             │
│  │                                                  │             │
│  │  Log Groups:                                     │             │
│  │    - /aws/ec2/instance-1                        │             │
│  │    - /aws/alb/devops-alb                        │             │
│  │    - /aws/cloudfront/devops-cdn                 │             │
│  │                                                  │             │
│  │  Metrics:                                        │             │
│  │    - CPU, Memory, Disk usage                    │             │
│  │    - Network I/O                                 │             │
│  └──────────────────────────────────────────────────┘             │
│                                                                   │
│  ┌────────────────────────────────────────────────┐              │
│  │         S3 Bucket (Access Logs)                │              │
│  │                                                 │              │
│  │  Folders:                                       │              │
│  │    - alb-logs/                                  │              │
│  │    - cloudfront-logs/                           │              │
│  │                                                 │              │
│  │  Lifecycle:                                     │              │
│  │    - 30 days → Standard-IA                     │              │
│  │    - 60 days → Glacier                         │              │
│  │    - 90 days → Expire                          │              │
│  └────────────────────────────────────────────────┘              │
│                                                                   │
│  ┌────────────────────────────────────────────────┐              │
│  │         Route53 (DNS)                           │              │
│  │                                                 │              │
│  │  Records:                                       │              │
│  │    - example.com → CloudFront (A, Alias)       │              │
│  │    - alb.example.com → ALB (A, Alias)          │              │
│  │    - Validation records for ACM                │              │
│  └────────────────────────────────────────────────┘              │
│                                                                   │
│  ┌────────────────────────────────────────────────┐              │
│  │      ACM Certificates (SSL/TLS)                 │              │
│  │                                                 │              │
│  │  - Regional cert (ALB) → ap-southeast-2        │              │
│  │  - Global cert (CloudFront) → us-east-1        │              │
│  │  - DNS validation via Route53                  │              │
│  └────────────────────────────────────────────────┘              │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## Traffic Flow

### 1. Without Domain (Basic)
```
User → ALB DNS (http://alb-xxxxx.region.elb.amazonaws.com) → EC2 Instance
```

### 2. With Domain (ALB Only)
```
User → Route53 (alb.example.com) → ALB → EC2 Instance
```

### 3. With Domain + CloudFront
```
User → Route53 (example.com) → CloudFront Edge → ALB → EC2 Instance
```

## Security Boundaries

```
┌──────────────────────┐
│   Public Access      │  Ports: 80, 443
├──────────────────────┤
│   CloudFront         │  HTTPS only
│   Load Balancer      │  HTTP/HTTPS
└──────────┬───────────┘
           │
┌──────────▼───────────┐
│   VPC Internal       │  Private IPs
├──────────────────────┤
│   EC2 Instance       │  Port 80 from ALB only
│   Private Subnets    │  No internet access
└──────────────────────┘
```

## Module Dependencies

```
vpc
 ├── alb (needs: vpc_id, subnet_ids)
 │    └── vm (needs: vpc_id, subnet_id)
 │
 ├── s3_logs (needs: nothing)
 │
 ├── certificate_alb (needs: route53 for validation)
 │
 ├── certificate_cloudfront (needs: route53 for validation)
 │
 ├── route53 (needs: alb, cloudfront, certificates)
 │
 └── cloudfront (needs: alb, certificate_cloudfront, s3_logs)
```

## Logging Data Flow

```
EC2 Instance
 ├── CloudWatch Agent → CloudWatch Logs (/aws/ec2/*)
 └── Apache logs → CloudWatch Logs

ALB
 └── Access Logs → S3 (alb-logs/) → (optional) CloudWatch

CloudFront
 └── Access Logs → S3 (cloudfront-logs/)

All CloudWatch Logs
 └── Retention: 7 days
```
