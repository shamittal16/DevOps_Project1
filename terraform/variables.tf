variable "aws_region" {
  description = "AWS region to create resources in"
  default     = "ap-southeast-2"
}

variable "domain_name" {
  description = "Domain name for the application (e.g., example.com)"
  type        = string
  default     = ""
}

variable "create_route53_zone" {
  description = "Whether to create a new Route53 hosted zone"
  type        = bool
  default     = false
}

variable "enable_cloudfront" {
  description = "Whether to enable CloudFront distribution"
  type        = bool
  default     = true
}

variable "enable_alb_logging" {
  description = "Whether to enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "enable_cloudfront_logging" {
  description = "Whether to enable CloudFront access logging to S3"
  type        = bool
  default     = true
}
