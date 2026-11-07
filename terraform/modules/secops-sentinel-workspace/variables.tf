variable "name" {
  type = string

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]{2,61}[A-Za-z0-9]$", var.name))
    error_message = "name must be 4-63 letters, digits or hyphens and not start or end with a hyphen."
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "retention_in_days" {
  type        = number
  description = "Interactive retention. Microsoft Sentinel includes 90 days at no extra retention cost."
  default     = 90

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730."
  }
}

variable "daily_quota_gb" {
  type        = number
  description = "-1 for no cap. A cap silently drops security telemetry once reached, so use it only in labs."
  default     = -1
}

variable "tenant_id" {
  type = string
}

variable "data_connectors" {
  type = object({
    entra_id_protection     = optional(bool, true)
    defender_xdr            = optional(bool, true)
    office_365              = optional(bool, true)
    defender_for_identity   = optional(bool, false)
    defender_for_cloud_apps = optional(bool, false)
    defender_for_endpoint   = optional(bool, false)
    threat_intelligence     = optional(bool, true)
  })
  description = "Defender XDR already streams Defender for Identity, Endpoint and Cloud Apps alerts; enable the per-product connectors only when the XDR connector cannot be used."
  default     = {}
}

variable "threat_intelligence_lookback_date" {
  type        = string
  description = "RFC 3339 start date for the Microsoft emerging threat feed import. Changing it recreates the connector."
  default     = "2026-01-01T00:00:00Z"

  validation {
    condition     = can(formatdate("YYYY", var.threat_intelligence_lookback_date))
    error_message = "threat_intelligence_lookback_date must be an RFC 3339 timestamp."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
