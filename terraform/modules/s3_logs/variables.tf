variable "bucket_name" {
  description = "Name of the S3 bucket for logs"
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow bucket deletion even when it contains objects"
  type        = bool
  default     = false
}

variable "enable_versioning" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = false
}

variable "lifecycle_rules_enabled" {
  description = "Enable lifecycle rules for log management"
  type        = bool
  default     = true
}

variable "log_expiration_days" {
  description = "Number of days after which logs expire"
  type        = number
  default     = 90
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days after which noncurrent versions expire"
  type        = number
  default     = 30
}

variable "transition_to_ia_days" {
  description = "Number of days after which logs transition to IA storage (0 to disable)"
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Number of days after which logs transition to Glacier (0 to disable)"
  type        = number
  default     = 60
}

variable "alb_log_delivery_principal" {
  description = "AWS principal ARN for ALB log delivery (region-specific)"
  type        = string
}

variable "enable_cloudfront_logs" {
  description = "Whether to enable CloudFront log delivery permissions"
  type        = bool
  default     = false
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution (required if enable_cloudfront_logs is true)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
