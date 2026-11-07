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

variable "intune_user_group_names" {
  type        = list(string)
  default     = []
  description = "Existing user groups (display names, e.g. persona groups from 10-entra-foundation) added to app protection and enrollment restriction targeting alongside the group this stack creates."
}

variable "compliance_grace_period_hours" {
  type    = number
  default = 24

  validation {
    condition     = var.compliance_grace_period_hours >= 0 && var.compliance_grace_period_hours <= 168
    error_message = "compliance_grace_period_hours must be between 0 and 168."
  }
}

variable "defender_for_endpoint_connected" {
  type        = bool
  default     = false
  description = "Set once the Microsoft Defender for Endpoint connector is enabled in Intune; turns on machine risk in compliance and deploys EDR onboarding."
}

variable "app_protection_level" {
  type    = number
  default = 2

  validation {
    condition     = contains([1, 2, 3], var.app_protection_level)
    error_message = "app_protection_level must be 1, 2 or 3."
  }
}

variable "asr_rule_overrides" {
  type        = map(string)
  default     = {}
  description = "Move ASR rules from audit to block once Defender reporting shows no business impact."
}

variable "update_rings" {
  type = map(object({
    quality_deferral_days = number
    quality_deadline_days = number
    feature_deadline_days = number
    grace_period_days     = number
  }))
  default = {
    pilot = { quality_deferral_days = 0, quality_deadline_days = 2, feature_deadline_days = 2, grace_period_days = 1 }
    broad = { quality_deferral_days = 7, quality_deadline_days = 3, feature_deadline_days = 7, grace_period_days = 2 }
  }

  validation {
    condition     = contains(keys(var.update_rings), "pilot") && contains(keys(var.update_rings), "broad")
    error_message = "update_rings must define pilot and broad."
  }
}

variable "feature_update_version" {
  type    = string
  default = "Windows 11, version 25H2"
}

variable "device_categories" {
  type = map(string)
  default = {
    "Corporate-Standard"   = "Standard knowledge worker device"
    "Corporate-Privileged" = "Privileged access workstation"
    "Frontline-Shared"     = "Shared frontline or kiosk device"
  }
}
