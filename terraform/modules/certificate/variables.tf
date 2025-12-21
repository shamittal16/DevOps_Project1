variable "domain_name" {
  description = "Domain name for the certificate"
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names for the certificate"
  type        = list(string)
  default     = []
}

variable "validate_certificate" {
  description = "Whether to wait for certificate validation"
  type        = bool
  default     = true
}

variable "validation_record_fqdns" {
  description = "List of FQDNs for certificate validation records"
  type        = list(string)
  default     = []
}

variable "validation_timeout" {
  description = "Timeout for certificate validation"
  type        = string
  default     = "45m"
}

variable "tags" {
  description = "Tags to apply to the certificate"
  type        = map(string)
  default     = {}
}
