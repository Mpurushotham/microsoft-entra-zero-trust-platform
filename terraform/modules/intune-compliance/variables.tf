variable "name_prefix" {
  type    = string
  default = "zt"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.name_prefix))
    error_message = "name_prefix must be 2-10 lowercase alphanumeric characters starting with a letter."
  }
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "role_scope_tag_ids" {
  type        = list(string)
  default     = ["0"]
  description = "Intune scope tag IDs applied to every policy. \"0\" is the built-in Default tag."
}

variable "platforms" {
  type    = set(string)
  default = ["windows", "macos", "ios", "android_fully_managed", "android_work_profile"]

  validation {
    condition     = alltrue([for p in var.platforms : contains(["windows", "macos", "ios", "android_fully_managed", "android_work_profile"], p)])
    error_message = "platforms may only contain windows, macos, ios, android_fully_managed, android_work_profile."
  }
}

variable "os_minimum_versions" {
  type        = map(string)
  default     = {}
  description = "Per-platform overrides of the minimum OS version. Keys match var.platforms."

  validation {
    condition     = alltrue([for k in keys(var.os_minimum_versions) : contains(["windows", "macos", "ios", "android_fully_managed", "android_work_profile"], k)])
    error_message = "os_minimum_versions keys must be valid platform keys."
  }
}

variable "noncompliance_grace_period_hours" {
  type        = number
  default     = 24
  description = "Hours between a device failing a rule and being marked noncompliant (and blocked by Conditional Access)."

  validation {
    condition     = var.noncompliance_grace_period_hours >= 0 && var.noncompliance_grace_period_hours <= 8760
    error_message = "noncompliance_grace_period_hours must be between 0 and 8760."
  }
}

variable "device_threat_protection" {
  type = object({
    enabled = bool
    level   = string
  })
  default = {
    enabled = false
    level   = "medium"
  }
  description = "Require a Microsoft Defender for Endpoint machine risk score at or below level. Needs the MDE connector enabled in Intune."

  validation {
    condition     = contains(["secured", "low", "medium", "high"], var.device_threat_protection.level)
    error_message = "device_threat_protection.level must be secured, low, medium or high."
  }
}

variable "assignments" {
  type = map(object({
    include_group_ids = list(string)
    exclude_group_ids = optional(list(string), [])
  }))
  default     = {}
  description = "Group assignments keyed by platform key."
}
