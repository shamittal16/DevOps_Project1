variable "domain_name" {
  description = "Domain name for the Route53 zone"
  type        = string
}

variable "create_zone" {
  description = "Whether to create a new Route53 zone or use existing one"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "Whether to force destroy the zone even if it contains records"
  type        = bool
  default     = false
}

variable "certificate_validation_records" {
  description = "Map of certificate validation records to create"
  type = map(object({
    name   = string
    type   = string
    record = string
  }))
  default = {}
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
  default     = null
}

variable "alb_zone_id" {
  description = "Route53 zone ID of the Application Load Balancer"
  type        = string
  default     = null
}

variable "alb_record_name" {
  description = "Record name for the ALB alias (empty for apex)"
  type        = string
  default     = ""
}

variable "alb_evaluate_target_health" {
  description = "Whether to evaluate ALB target health"
  type        = bool
  default     = true
}

variable "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  type        = string
  default     = null
}

variable "cloudfront_zone_id" {
  description = "Route53 zone ID for CloudFront (typically Z2FDTNDATAQYW2)"
  type        = string
  default     = "Z2FDTNDATAQYW2"
}

variable "cloudfront_record_name" {
  description = "Record name for the CloudFront alias (empty for apex)"
  type        = string
  default     = ""
}

variable "additional_records" {
  description = "Additional DNS records to create"
  type = map(object({
    name    = string
    type    = string
    records = list(string)
    ttl     = optional(number)
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
