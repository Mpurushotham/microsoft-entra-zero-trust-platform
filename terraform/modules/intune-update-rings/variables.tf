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
  description = "Intune scope tag IDs applied to every object. \"0\" is the built-in Default tag."
}

variable "rings" {
  type = map(object({
    quality_deferral_days = number
    feature_deferral_days = optional(number, 0)
    quality_deadline_days = number
    feature_deadline_days = number
    grace_period_days     = number
    include_group_ids     = list(string)
    exclude_group_ids     = optional(list(string), [])
  }))
  description = "Windows Update for Business rings keyed by ring name (e.g. pilot, broad). Feature versions are pinned by feature_update_profiles, so feature deferral normally stays 0."

  validation {
    condition = alltrue([for r in values(var.rings) :
      r.quality_deferral_days >= 0 && r.quality_deferral_days <= 30 &&
      r.feature_deferral_days >= 0 && r.feature_deferral_days <= 365 &&
      r.quality_deadline_days >= 0 && r.quality_deadline_days <= 30 &&
      r.feature_deadline_days >= 0 && r.feature_deadline_days <= 30 &&
      r.grace_period_days >= 0 && r.grace_period_days <= 7
    ])
    error_message = "Deferrals: quality 0-30, feature 0-365; deadlines 0-30; grace period 0-7 days."
  }
}

variable "active_hours" {
  type = object({
    start = string
    end   = string
  })
  default = {
    start = "08:00:00"
    end   = "17:00:00"
  }

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3]):00:00$", var.active_hours.start)) && can(regex("^([01][0-9]|2[0-3]):00:00$", var.active_hours.end))
    error_message = "active_hours start and end must be whole hours in HH:00:00 format."
  }
}

variable "feature_update_profiles" {
  type = map(object({
    feature_update_version = string
    include_group_ids      = list(string)
    exclude_group_ids      = optional(list(string), [])
  }))
  default     = {}
  description = "Feature update profiles keyed by name. feature_update_version uses the Intune catalog string, e.g. \"Windows 11, version 25H2\"."

  validation {
    condition     = alltrue([for p in values(var.feature_update_profiles) : can(regex("^Windows 1[01], version [0-9]{2}H[12]$", p.feature_update_version))])
    error_message = "feature_update_version must look like \"Windows 11, version 25H2\"."
  }
}
