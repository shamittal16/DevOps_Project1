# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

# EC2 Instance Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.vm.instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = module.vm.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = module.vm.instance_private_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.vm.security_group_id
}

# CloudWatch Outputs
output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.vm_logs.name
}

# AMI Outputs
output "ubuntu_ami_id" {
  description = "Ubuntu AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}

output "ubuntu_ami_name" {
  description = "Ubuntu AMI name"
  value       = data.aws_ami.ubuntu.name
}

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.alb.alb_arn
}

output "alb_url" {
  description = "URL to access the ALB"
  value       = "http://${module.alb.alb_dns_name}"
}

# Certificate Outputs
output "alb_certificate_arn" {
  description = "ARN of the ALB certificate"
  value       = var.domain_name != "" ? module.certificate_alb[0].certificate_arn : null
}

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront certificate"
  value       = var.domain_name != "" && var.enable_cloudfront ? module.certificate_cloudfront[0].certificate_arn : null
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 zone ID"
  value       = var.domain_name != "" ? module.route53[0].zone_id : null
}

output "route53_name_servers" {
  description = "Name servers for the Route53 zone"
  value       = var.domain_name != "" && var.create_route53_zone ? module.route53[0].name_servers : null
}

output "alb_domain_name" {
  description = "Custom domain name for ALB"
  value       = var.domain_name != "" ? "alb.${var.domain_name}" : null
}

output "website_domain_name" {
  description = "Custom domain name for the website"
  value       = var.domain_name != "" ? var.domain_name : null
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_id : null
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = var.enable_cloudfront ? module.cloudfront[0].distribution_domain_name : null
}

output "cloudfront_url" {
  description = "URL to access CloudFront"
  value       = var.enable_cloudfront ? "https://${module.cloudfront[0].distribution_domain_name}" : null
}

# S3 Logs Outputs
output "logs_bucket_name" {
  description = "Name of the S3 bucket for access logs"
  value       = var.enable_alb_logging || var.enable_cloudfront_logging ? module.s3_logs[0].bucket_id : null
}

# Quick Access URLs
output "access_instructions" {
  description = "Instructions for accessing the application"
  value       = <<-EOT
    Access your application via ALB DNS: http://${module.alb.alb_dns_name}
    ${var.domain_name != "" ? "Custom domain (after DNS propagation): https://${var.domain_name}" : ""}
    ${var.domain_name != "" ? "ALB custom domain: https://alb.${var.domain_name}" : ""}
  EOT
}
