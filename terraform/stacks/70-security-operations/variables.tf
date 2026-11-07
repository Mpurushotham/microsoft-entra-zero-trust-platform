variable "name_prefix" {
  type    = string
  default = "zt"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.name_prefix))
    error_message = "name_prefix must be 2-8 lowercase letters or digits, starting with a letter."
  }
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Defaults to the resource group created by stack 00."
  default     = null
}

variable "retention_in_days" {
  type    = number
  default = 90
}

variable "daily_quota_gb" {
  type    = number
  default = -1
}

variable "entra_log_categories" {
  type    = set(string)
  default = null
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
  default = {}
}

variable "break_glass_upns" {
  type = set(string)
}

variable "business_hours" {
  type = object({
    start_hour       = number
    end_hour         = number
    utc_offset_hours = number
    workdays         = list(number)
  })
  default = {
    start_hour       = 7
    end_hour         = 19
    utc_offset_hours = 0
    workdays         = [1, 2, 3, 4, 5]
  }
}

variable "mfa_fatigue_threshold" {
  type    = number
  default = 5
}

variable "disabled_rules" {
  type    = set(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
