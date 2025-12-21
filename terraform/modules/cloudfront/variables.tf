variable "distribution_name" {
  description = "Name for the CloudFront distribution"
  type        = string
}

variable "enabled" {
  description = "Whether the distribution is enabled"
  type        = bool
  default     = true
}

variable "is_ipv6_enabled" {
  description = "Whether IPv6 is enabled for the distribution"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Comment for the distribution"
  type        = string
  default     = ""
}

variable "default_root_object" {
  description = "Object that CloudFront returns when a user requests the root URL"
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "Price class for the distribution"
  type        = string
  default     = "PriceClass_100"
}

variable "aliases" {
  description = "Extra CNAMEs (alternate domain names) for this distribution"
  type        = list(string)
  default     = []
}

variable "origin_domain_name" {
  description = "DNS domain name of the origin (e.g., ALB DNS name)"
  type        = string
}

variable "origin_id" {
  description = "Unique identifier for the origin"
  type        = string
  default     = "primary"
}

variable "origin_http_port" {
  description = "HTTP port for the custom origin"
  type        = number
  default     = 80
}

variable "origin_https_port" {
  description = "HTTPS port for the custom origin"
  type        = number
  default     = 443
}

variable "origin_protocol_policy" {
  description = "Origin protocol policy (http-only, https-only, or match-viewer)"
  type        = string
  default     = "https-only"
}

variable "origin_ssl_protocols" {
  description = "SSL/TLS protocols for the origin"
  type        = list(string)
  default     = ["TLSv1.2"]
}

variable "custom_headers" {
  description = "Custom headers to send to the origin"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "allowed_methods" {
  description = "HTTP methods that CloudFront processes and forwards to the origin"
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
}

variable "cached_methods" {
  description = "HTTP methods for which CloudFront caches responses"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "forward_query_string" {
  description = "Whether to forward query strings to the origin"
  type        = bool
  default     = true
}

variable "forward_headers" {
  description = "Headers to forward to the origin"
  type        = list(string)
  default     = ["Host"]
}

variable "forward_cookies" {
  description = "How to forward cookies (none, whitelist, or all)"
  type        = string
  default     = "none"
}

variable "viewer_protocol_policy" {
  description = "Protocol that viewers can use to access content (allow-all, https-only, redirect-to-https)"
  type        = string
  default     = "redirect-to-https"
}

variable "min_ttl" {
  description = "Minimum amount of time (in seconds) that objects stay in CloudFront caches"
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "Default amount of time (in seconds) that objects stay in CloudFront caches"
  type        = number
  default     = 3600
}

variable "max_ttl" {
  description = "Maximum amount of time (in seconds) that objects stay in CloudFront caches"
  type        = number
  default     = 86400
}

variable "compress" {
  description = "Whether CloudFront automatically compresses content"
  type        = bool
  default     = true
}

variable "logging_bucket" {
  description = "S3 bucket for CloudFront access logs (must end with .s3.amazonaws.com)"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for CloudFront access logs in S3"
  type        = string
  default     = "cloudfront-logs/"
}

variable "logging_include_cookies" {
  description = "Whether to include cookies in access logs"
  type        = bool
  default     = false
}

variable "geo_restriction_type" {
  description = "Method to restrict distribution of content by country (none, whitelist, or blacklist)"
  type        = string
  default     = "none"
}

variable "geo_restriction_locations" {
  description = "ISO 3166-1-alpha-2 country codes for geo restriction"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
  default     = null
}

variable "minimum_protocol_version" {
  description = "Minimum version of the SSL protocol for HTTPS connections"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "enable_cloudwatch_logs" {
  description = "Whether to create CloudWatch log group"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
