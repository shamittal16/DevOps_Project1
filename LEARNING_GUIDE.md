# DevOps Best Practices: A Learning Journey

## Overview

This document explains the evolution of this infrastructure project from a simple EC2 instance to a production-ready, enterprise-grade web application deployment. Each change demonstrates key DevOps and cloud engineering principles that every junior engineer should understand and apply.

---

## Phase 1: From Hard-Coded Resources to Modular Architecture

### What Changed
We transformed individual Terraform resources into reusable modules.

### Why This Matters

**Before:**
```hcl
# Everything in one file, hard-coded values
resource "aws_instance" "first-aws-ec2" {
  ami           = "ami-068c0051b15cdb816"  # Hard-coded
  instance_type = "t3.micro"
  region        = "us-east-1"              # Hard-coded
}
```

**After:**
```hcl
# Modular, reusable, configurable
module "vm" {
  source = "./modules/vm"
  
  instance_name = var.instance_name
  ami          = data.aws_ami.ubuntu.id   # Dynamic lookup
  vpc_id       = module.vpc.vpc_id        # References
}
```

### Key Lessons

1. **DRY Principle (Don't Repeat Yourself)**
   - Modules allow you to reuse code across environments
   - Change once, apply everywhere
   - Example: Use the same VPC module for dev, staging, and production

2. **Separation of Concerns**
   - Each module handles one responsibility
   - VPC module = networking only
   - VM module = compute only
   - Easier to test, maintain, and troubleshoot

3. **Abstraction**
   - Hide complexity behind simple interfaces
   - Users don't need to know VPC internals to use the module
   - Reduces cognitive load and errors

**Real-World Benefit:** A team member can deploy a new environment in minutes instead of hours, with confidence that it follows best practices.

---

## Phase 2: Dynamic AMI Lookup

### What Changed
```hcl
# Before: Hard-coded AMI ID (breaks in different regions)
ami = "ami-068c0051b15cdb816"

# After: Dynamic lookup
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

### Why This Matters

**Problems with Hard-Coded AMIs:**
1. AMI IDs are region-specific (ami-xxx in us-east-1 ≠ same OS in eu-west-1)
2. AMIs get deprecated and deleted
3. Security updates require manual changes
4. No way to ensure you're using the latest version

**Benefits of Dynamic Lookup:**
1. Always gets the latest Ubuntu 22.04 image
2. Works in any AWS region automatically
3. Includes security patches automatically
4. Self-documenting (clear which OS we want)

**Key Lesson:** Infrastructure should be portable and self-maintaining. Never hard-code values that change or vary by environment/region.

---

## Phase 3: Comprehensive Logging and Monitoring

### What Changed
Added CloudWatch agent, logs, and metrics to the EC2 instance.

### Why This Matters

**Without Monitoring:**
- "The site is down" → No idea why
- "It was slow yesterday" → No data to analyze
- "When did this start?" → Can't tell
- Debugging requires SSH access (security risk)

**With Monitoring:**
```hcl
# CloudWatch Logs capture everything
- /aws/ec2/instance-1/syslog       # System events
- /aws/ec2/instance-1/auth.log     # Security events
- /aws/ec2/instance-1/apache       # Application logs

# Metrics show resource usage
- CPU usage over time
- Memory consumption
- Disk space
- Network I/O
```

### Key Lessons

1. **Observability is Not Optional**
   - You can't fix what you can't see
   - Logs answer "what happened?"
   - Metrics answer "is this normal?"
   - Together they enable proactive problem-solving

2. **Centralized Logging**
   - All logs in one place (CloudWatch)
   - No SSH needed to view logs
   - Can query across multiple instances
   - Survives instance termination

3. **IAM Roles Over Credentials**
   ```hcl
   # NEVER do this
   aws_access_key = "AKIAIOSFODNN7EXAMPLE"
   
   # ALWAYS do this
   iam_instance_profile = aws_iam_instance_profile.vm_profile.name
   ```
   - Credentials can be stolen
   - Roles are temporary and auto-rotate
   - Roles follow the instance (auto-scaling safe)

**Real-World Benefit:** When your app crashes at 3 AM, you can troubleshoot from your laptop instead of getting dressed and finding your laptop to SSH into a server.

---

## Phase 4: Network Isolation with VPC

### What Changed
Created a custom VPC with public and private subnets instead of using the default VPC.

### Why This Matters

**Default VPC Problems:**
- Shared with other resources (blast radius)
- Can't control IP addressing
- Limited customization
- Deleted = everything breaks

**Custom VPC Benefits:**
```
Public Subnets (10.0.1.0/24)
├── Load Balancer (internet-facing)
└── Bastion host (controlled access)

Private Subnets (10.0.10.0/24)
├── Application servers (no direct internet)
├── Databases (protected)
└── Internal services (secure)
```

### Key Lessons

1. **Defense in Depth**
   - Multiple layers of security
   - Even if one layer fails, others protect you
   - Public subnet ≠ publicly accessible (still need security groups)

2. **Principle of Least Privilege (Network Edition)**
   - Only the load balancer needs internet access
   - Application servers only talk to what they need
   - Databases never touch the internet

3. **Subnet Planning**
   ```
   VPC: 10.0.0.0/16 = 65,536 IPs
   ├── Public:  10.0.0.0/20  = 4,096 IPs
   ├── Private: 10.0.16.0/20 = 4,096 IPs
   └── Reserved: For future expansion
   ```
   - Plan for growth
   - Don't run out of IPs
   - Organize by function

**Real-World Benefit:** A compromised web server can't directly attack your database. An attacker needs to breach multiple layers.

---

## Phase 5: Load Balancing and High Availability

### What Changed
Added an Application Load Balancer instead of connecting directly to EC2.

### Why This Matters

**Single Instance Problems:**
```
User → EC2 Instance
       ↓ (dies)
    💥 Site Down 💥
```

**Load Balancer Solution:**
```
                 ┌→ EC2 Instance 1
User → ALB ──────┼→ EC2 Instance 2
                 └→ EC2 Instance 3
                    (any one can fail safely)
```

### Key Lessons

1. **Single Point of Failure (SPOF)**
   - If one component failing breaks everything, that's a SPOF
   - SPOFs are unacceptable in production
   - Always have redundancy for critical paths

2. **Health Checks**
   ```hcl
   health_check {
     path     = "/health"
     interval = 30
     timeout  = 5
   }
   ```
   - Automatic detection of failures
   - Automatic traffic rerouting
   - No human intervention needed
   - Faster than monitoring alerts

3. **SSL Termination**
   - ALB handles HTTPS encryption/decryption
   - Backend servers use simpler HTTP
   - One place to manage certificates
   - Better performance (offloaded from app servers)

4. **Zero-Downtime Deployments**
   - Deploy new version
   - ALB health check fails old version
   - Traffic automatically shifts to new version
   - Old version removed after drain period

**Real-World Benefit:** You can deploy updates during business hours. A crashed instance doesn't wake you up at night.

---

## Phase 6: SSL Certificates and HTTPS Everywhere

### What Changed
Implemented automatic SSL certificate management with ACM.

### Why This Matters

**HTTP Problems:**
- Passwords transmitted in plain text
- Session hijacking possible
- No data integrity
- Browser warnings scare users
- Google ranks HTTP sites lower

**HTTPS Benefits:**
- Encrypted communication
- Verified identity
- Data integrity
- User trust
- SEO boost

### Key Lessons

1. **Automate Certificate Management**
   ```hcl
   # Manual process (old way)
   1. Generate CSR
   2. Submit to CA
   3. Validate via email
   4. Download cert
   5. Install on server
   6. Renew every 90 days manually
   
   # Automated process (modern way)
   module "certificate" {
     domain_name = "example.com"
     validation_method = "DNS"  # Fully automated
   }
   ```

2. **DNS Validation vs Email Validation**
   - DNS = fully automatable
   - Email = requires human intervention
   - DNS = works for wildcard certs
   - Email = breaks if domain changes hands

3. **Certificate Placement**
   - CloudFront certificates → us-east-1 (AWS requirement)
   - ALB certificates → same region as ALB
   - Forgetting this = hours of debugging

4. **HTTP → HTTPS Redirect**
   ```hcl
   # Force all traffic to HTTPS
   default_action {
     type = "redirect"
     redirect {
       protocol    = "HTTPS"
       status_code = "HTTP_301"  # Permanent
     }
   }
   ```
   - Protect users who type "http://"
   - 301 = browsers remember and auto-upgrade

**Real-World Benefit:** Certificates are free, auto-renew, and users' data is protected. No more expired certificate emergencies.

---

## Phase 7: Global Content Delivery with CloudFront

### What Changed
Added CloudFront CDN in front of the ALB.

### Why This Matters

**Without CDN:**
```
Tokyo User → (12,000 km) → Oregon Server → (12,000 km) → Tokyo User
Time: 300ms latency + transfer time
```

**With CDN:**
```
Tokyo User → (50 km) → Tokyo Edge → (cached!) → Tokyo User
Time: 5ms latency + transfer time
```

### Key Lessons

1. **Latency = User Experience**
   - Every 100ms delay = 1% revenue loss (Amazon's data)
   - Users expect instant responses
   - CDN reduces latency by 10-50x for global users

2. **Caching Strategy**
   ```hcl
   # Static content (images, CSS, JS)
   default_ttl = 86400  # 24 hours
   
   # Dynamic content (API responses)
   default_ttl = 0      # No caching
   
   # Semi-dynamic (user profiles)
   default_ttl = 300    # 5 minutes
   ```
   - Balance freshness vs performance
   - More caching = lower origin load
   - Invalidations cost money (design to minimize)

3. **DDoS Protection**
   - CloudFront absorbs attack traffic
   - Origins stay protected
   - Built-in AWS Shield protection
   - Scales automatically

4. **Cost Optimization**
   ```hcl
   price_class = "PriceClass_100"  # US, Canada, Europe
   ```
   - Not every app needs global distribution
   - Match coverage to user base
   - Can save 50% on CDN costs

**Real-World Benefit:** A small web app can handle millions of users globally without breaking a sweat (or the bank).

---

## Phase 8: Automated DNS Management

### What Changed
Integrated Route53 for DNS with automatic certificate validation.

### Why This Matters

**Manual DNS:**
```
1. Create certificate
2. Get validation CNAME
3. Log into DNS provider
4. Add CNAME record
5. Wait 30 minutes
6. Check if validated
7. Repeat for CloudFront cert
```

**Automated DNS:**
```hcl
# Terraform does all of this automatically
certificate_validation_records = {
  for dvo in module.certificate.domain_validation_options : 
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
}
```

### Key Lessons

1. **Infrastructure as Code for DNS**
   - DNS changes are versioned
   - Can be reviewed before applying
   - Can be rolled back
   - Reduces human error

2. **Alias Records vs CNAME Records**
   ```hcl
   # Alias (AWS-only, better)
   - Free queries
   - Works at apex (example.com)
   - Can point to AWS resources
   
   # CNAME (standard, limited)
   - Charged per query
   - Doesn't work at apex
   - Can point anywhere
   ```

3. **DNS Propagation**
   - Changes aren't instant
   - TTL affects update time
   - Lower TTL = faster updates = more queries = higher cost
   - Recommended: 300s during changes, 3600s normally

**Real-World Benefit:** Deploying to a new domain takes 10 minutes instead of 2 hours, and doesn't require remembering 15 manual steps.

---

## Phase 9: Centralized Log Storage with S3

### What Changed
Created an S3 bucket with lifecycle policies for ALB and CloudFront access logs.

### Why This Matters

**Without Centralized Storage:**
- Logs scattered across services
- No long-term retention
- Hard to analyze trends
- Compliance issues
- Costly to store

**With S3 Lifecycle Management:**
```hcl
Day 0-30:   STANDARD      ($0.023/GB)
Day 30-60:  STANDARD_IA   ($0.0125/GB) ← 45% cheaper
Day 60-90:  GLACIER       ($0.004/GB)  ← 83% cheaper
Day 90+:    DELETED       ($0)         ← Compliance met
```

### Key Lessons

1. **Storage Classes Are Cost Optimization**
   - Different access patterns need different storage
   - Automated transitions save money without effort
   - Example: 1TB for 90 days = $40 vs $69 (42% savings)

2. **Compliance and Retention**
   - Many industries require log retention
   - 90 days is common
   - Automated expiration prevents accidental deletion
   - Proves compliance during audits

3. **Log Analysis**
   ```hcl
   # Enable Athena for SQL queries
   SELECT 
     request_ip,
     COUNT(*) as requests
   FROM alb_logs
   WHERE status = 500
   GROUP BY request_ip;
   ```
   - Turn logs into insights
   - Find patterns and issues
   - No custom log parser needed

4. **Bucket Policies for Service Access**
   - Each AWS service has specific requirements
   - ALB needs specific account principal per region
   - CloudFront needs distribution ARN condition
   - Incorrect policy = no logs (silent failure)

**Real-World Benefit:** Store years of logs for pennies, query them instantly, and prove compliance effortlessly.

---

## Phase 10: CI/CD with GitHub Actions

### What Changed
Enhanced Terraform workflow to generate plan summaries and post them to PRs.

### Why This Matters

**Without PR Comments:**
```
Developer: "I updated the security group"
Reviewer: "Looks good" (didn't actually check)
→ Deploys
→ Opens port 22 to internet
→ 💥 Security incident 💥
```

**With PR Comments:**
```
Terraform Plan Summary: Create=1, Update=2, Delete=0

├─ aws_security_group
│  └─ my-sg (update)
│     ~ ingress_rules: [0.0.0.0/0:22] → [10.0.0.0/16:22]

Reviewer: "Wait, why are we changing SSH access?"
→ Catches issue before deployment
```

### Key Lessons

1. **Shift Left Security**
   - Catch issues in PR, not production
   - Cheaper to fix earlier
   - Learning opportunity for developers
   - Reduces "roll-forward" emergencies

2. **Plan Visibility**
   - Terraform plans can be complex
   - Summarizing makes review possible
   - Automated review catches obvious issues
   - Humans focus on business logic

3. **Audit Trail**
   - PR comments = permanent record
   - Know who approved what
   - Understand why changes were made
   - Satisfies compliance requirements

4. **Cost Estimation**
   - Can add cost estimation to plan
   - "This change adds $500/month"
   - Catches expensive mistakes early
   - Enables budget-conscious development

**Real-World Benefit:** Security issues caught in review instead of production. Everyone knows what changed and why. No surprises on the AWS bill.

---

## Key Principles Summary

### 1. Automation Over Manual Process
**Why:** Humans make mistakes. Automation is consistent and documented.
**Example:** Automated certificate validation vs manual CNAME creation

### 2. Infrastructure as Code
**Why:** Version control, review, rollback, and reproduce environments.
**Example:** VPC modules deployed identically across dev/staging/prod

### 3. Security by Default
**Why:** Easier to start secure than retrofit security later.
**Example:** Encrypted volumes, private subnets, IAM roles

### 4. Observability from Day One
**Why:** Can't troubleshoot what you can't see.
**Example:** CloudWatch logs and metrics on all resources

### 5. Design for Failure
**Why:** Things will break. Plan for it.
**Example:** Multi-AZ deployment, health checks, auto-recovery

### 6. Cost-Conscious Architecture
**Why:** Cloud costs can spiral. Optimize proactively.
**Example:** S3 lifecycle policies, t3.micro instances, spot instances

### 7. Least Privilege Always
**Why:** Limit blast radius of compromise.
**Example:** Private subnets, security group restrictions, IAM policies

### 8. Documentation is Code
**Why:** Future you (and your team) will thank you.
**Example:** Module READMEs, variable descriptions, architecture diagrams

---

## What Makes This Production-Ready?

### ✅ High Availability
- Multi-AZ deployment
- Load balancer with health checks
- Auto-healing (if instance dies, recreate it)

### ✅ Security
- HTTPS everywhere
- Private subnets for sensitive resources
- Security groups with minimal access
- Encrypted storage
- IAM roles (no credentials)
- Regular security updates (latest AMI)

### ✅ Scalability
- ALB ready for auto-scaling group
- CloudFront handles traffic spikes
- Can add instances without code changes

### ✅ Maintainability
- Modular code (easy to update)
- Clear documentation
- Version controlled
- Automated testing in CI/CD

### ✅ Observability
- Centralized logging
- Metrics and monitoring
- Alerting capabilities
- Audit trails

### ✅ Cost Optimization
- Right-sized instances
- Storage lifecycle management
- Only pay for what you use
- Can scale down when idle

### ✅ Disaster Recovery
- Infrastructure as Code (can rebuild anywhere)
- Backups (if configured)
- Multi-region ready architecture
- Documented runbooks

---

## Common Anti-Patterns to Avoid

### ❌ Hard-Coding Values
```hcl
# Bad
region = "us-east-1"
ami = "ami-12345"

# Good
region = var.aws_region
ami = data.aws_ami.latest.id
```

### ❌ Monolithic Resources
```hcl
# Bad: 2000 line main.tf file

# Good: Organized modules
modules/
├── vpc/
├── compute/
└── storage/
```

### ❌ Storing Secrets in Code
```hcl
# Bad
database_password = "SuperSecret123"

# Good
database_password = data.aws_secretsmanager_secret_version.db.secret_string
```

### ❌ No State Locking
```hcl
# Bad: Local state
# Good: Remote state with locking
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    dynamodb_table = "terraform-lock"
  }
}
```

### ❌ Ignoring Cost Implications
```hcl
# Bad: Running 24/7 in dev
# Good: Shutdown dev instances at night
# Good: Use smaller instances in dev
```

---

## Your Learning Path

### Week 1-2: Understand the Basics
- [ ] Read all module READMEs
- [ ] Deploy the basic setup (no domain)
- [ ] Access the application via ALB DNS
- [ ] View logs in CloudWatch
- [ ] Understand the VPC structure

### Week 3-4: Explore Components
- [ ] SSH into instance (via Session Manager)
- [ ] Review security group rules
- [ ] Examine IAM policies
- [ ] Check S3 bucket policies
- [ ] Review CloudWatch metrics

### Week 5-6: Make Changes
- [ ] Add a new security group rule
- [ ] Change instance type
- [ ] Modify log retention
- [ ] Update Apache configuration
- [ ] Test failure scenarios

### Week 7-8: Advanced Features
- [ ] Add custom domain
- [ ] Enable CloudFront
- [ ] Set up Route53
- [ ] Configure certificates
- [ ] Implement auto-scaling (exercise)

### Week 9-10: Production Readiness
- [ ] Add automated backups
- [ ] Implement monitoring alerts
- [ ] Create disaster recovery plan
- [ ] Document runbooks
- [ ] Conduct failure drills

---

## Questions to Ask Yourself

1. **What happens if...?**
   - The database crashes?
   - AWS region goes down?
   - We get 10x traffic?
   - A developer pushes bad code?

2. **How would I...?**
   - Rollback a bad deployment?
   - Debug a 503 error?
   - Reduce costs by 30%?
   - Add a new environment?

3. **Why did we...?**
   - Use multi-AZ for the VPC?
   - Put app servers in private subnet?
   - Choose CloudFront over direct ALB?
   - Enable access logging?

If you can answer these questions, you understand the "why" behind the architecture. That's when you've truly learned.

---

## Additional Resources

### AWS Documentation
- [VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-best-practices.html)
- [ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [CloudFront Guide](https://docs.aws.amazon.com/cloudfront/)

### Terraform
- [Module Best Practices](https://www.terraform.io/docs/modules/index.html)
- [State Management](https://www.terraform.io/docs/state/index.html)

### DevOps Principles
- The Phoenix Project (book)
- Site Reliability Engineering (book)
- 12 Factor App methodology

---

## Conclusion

This infrastructure represents **years of lessons** condensed into a single, working example. Each decision has a "why" rooted in real production incidents, cost overruns, or security breaches that others have experienced.

Your job as a junior DevOps engineer isn't to memorize all of this—it's to **understand the principles** so you can apply them to new situations. When you face a new problem, ask:

1. How can I automate this?
2. What happens when this fails?
3. How will I know if it's working?
4. What's the security implication?
5. What will this cost?

Answer those questions, and you're thinking like a senior engineer.

**Welcome to the journey. Keep learning. Keep building. Keep asking "why?"**
