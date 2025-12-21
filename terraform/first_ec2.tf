provider "aws" {
  region = var.aws_region
}

# For CloudFront certificates, need to create them in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ALB Log Delivery Principal (region-specific)
# See: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html
locals {
  alb_log_principals = {
    "us-east-1"      = "arn:aws:iam::127311923021:root"
    "us-east-2"      = "arn:aws:iam::033677994240:root"
    "us-west-1"      = "arn:aws:iam::027434742980:root"
    "us-west-2"      = "arn:aws:iam::797873946194:root"
    "ap-southeast-1" = "arn:aws:iam::114774131450:root"
    "ap-southeast-2" = "arn:aws:iam::783225319266:root"
    "ap-northeast-1" = "arn:aws:iam::582318560864:root"
    "eu-west-1"      = "arn:aws:iam::156460612806:root"
    "eu-central-1"   = "arn:aws:iam::054676820928:root"
  }
  alb_log_principal = lookup(local.alb_log_principals, var.aws_region, "arn:aws:iam::783225319266:root")
}

resource "aws_cloudwatch_log_group" "vm_logs" {
  name              = "/aws/ec2/instance-1"
  retention_in_days = 7

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role" "vm_role" {
  name = "ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "vm_cloudwatch_policy" {
  name = "cloudwatch-policy"
  role = aws_iam_role.vm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ec2:DescribeVolumes",
          "ec2:DescribeTags",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "vm_profile" {
  name = "ec2-cloudwatch-profile"
  role = aws_iam_role.vm_role.name

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "./modules/vpc"

  vpc_name             = "devops-vpc"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# S3 bucket for access logs
module "s3_logs" {
  count  = var.enable_alb_logging || var.enable_cloudfront_logging ? 1 : 0
  source = "./modules/s3_logs"

  bucket_name                  = "devops-access-logs-${data.aws_caller_identity.current.account_id}"
  alb_log_delivery_principal   = local.alb_log_principal
  enable_cloudfront_logs       = var.enable_cloudfront_logging
  cloudfront_distribution_arn  = var.enable_cloudfront ? module.cloudfront[0].distribution_arn : null

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

data "aws_caller_identity" "current" {}

# Security group for ALB
resource "aws_security_group" "alb" {
  name        = "alb-security-group"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

module "vm" {
  source = "./modules/vm"

  instance_name                = "instance-1"
  ami                          = data.aws_ami.ubuntu.id
  instance_type                = "t3.micro"
  subnet_id                    = module.vpc.public_subnet_ids[0]
  vpc_id                       = module.vpc.vpc_id
  associate_public_ip_address  = true
  iam_instance_profile         = aws_iam_instance_profile.vm_profile.name
  security_group_name          = "vm-security-group"
  security_group_description   = "Security group for EC2 instance"

  user_data = templatefile("${path.module}/user_data.sh", {
    log_group_name = aws_cloudwatch_log_group.vm_logs.name
    region         = var.aws_region
  })

  ingress_rules = [
    {
      cidr_ipv4   = module.vpc.vpc_cidr
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "Allow HTTP from VPC"
    },
    {
      cidr_ipv4   = module.vpc.vpc_cidr
      from_port   = 22
      to_port     = 22
      ip_protocol = "tcp"
      description = "Allow SSH from VPC"
    }
  ]

  egress_rules = [
    {
      cidr_ipv4   = "0.0.0.0/0"
      ip_protocol = "-1"
      description = "Allow all outbound"
    }
  ]

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# ACM Certificate for ALB (regional)
module "certificate_alb" {
  count  = var.domain_name != "" ? 1 : 0
  source = "./modules/certificate"

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validate_certificate      = false

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# ACM Certificate for CloudFront (must be in us-east-1)
module "certificate_cloudfront" {
  count  = var.domain_name != "" && var.enable_cloudfront ? 1 : 0
  source = "./modules/certificate"

  providers = {
    aws = aws.us_east_1
  }

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validate_certificate      = false

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Route53 DNS
module "route53" {
  count  = var.domain_name != "" ? 1 : 0
  source = "./modules/route53"

  domain_name                    = var.domain_name
  create_zone                    = var.create_route53_zone
  alb_dns_name                   = module.alb.alb_dns_name
  alb_zone_id                    = module.alb.alb_zone_id
  alb_record_name                = "alb.${var.domain_name}"
  cloudfront_domain_name         = var.enable_cloudfront ? module.cloudfront[0].distribution_domain_name : null
  cloudfront_record_name         = var.enable_cloudfront ? var.domain_name : ""

  # Certificate validation records
  certificate_validation_records = var.domain_name != "" ? merge(
    { for dvo in module.certificate_alb[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    } },
    var.enable_cloudfront ? { for dvo in module.certificate_cloudfront[0].domain_validation_options : "${dvo.domain_name}-cf" => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    } } : {}
  ) : {}

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Validate ALB certificate
module "certificate_alb_validation" {
  count  = var.domain_name != "" ? 1 : 0
  source = "./modules/certificate"

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validate_certificate      = true
  validation_record_fqdns   = module.route53[0].validation_record_fqdns

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  alb_name            = "devops-alb"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_ids  = [aws_security_group.alb.id]
  target_group_name   = "devops-tg"
  target_ids          = [module.vm.instance_id]
  certificate_arn     = var.domain_name != "" ? module.certificate_alb[0].certificate_arn : null
  access_logs_bucket  = var.enable_alb_logging ? module.s3_logs[0].bucket_id : null
  access_logs_prefix  = "alb-logs"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# CloudFront Distribution
module "cloudfront" {
  count  = var.enable_cloudfront ? 1 : 0
  source = "./modules/cloudfront"

  distribution_name      = "devops-cdn"
  origin_domain_name     = module.alb.alb_dns_name
  aliases                = var.domain_name != "" ? [var.domain_name, "www.${var.domain_name}"] : []
  acm_certificate_arn    = var.domain_name != "" ? module.certificate_cloudfront[0].certificate_arn : null
  logging_bucket         = var.enable_cloudfront_logging ? "${module.s3_logs[0].bucket_id}.s3.amazonaws.com" : null
  logging_prefix         = "cloudfront-logs/"
  origin_protocol_policy = var.domain_name != "" ? "https-only" : "http-only"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}