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

variable "platform_restrictions" {
  type = map(object({
    platform_blocked         = optional(bool, false)
    personal_devices_blocked = optional(bool, true)
    os_minimum_version       = optional(string)
    os_maximum_version       = optional(string)
    priority                 = number
  }))
  default = {
    windows        = { priority = 1 }
    ios            = { priority = 2, personal_devices_blocked = false }
    androidForWork = { priority = 3, personal_devices_blocked = false }
    android        = { priority = 4, platform_blocked = true }
    mac            = { priority = 5 }
  }
  description = "Per-platform enrollment restrictions keyed by Intune platformType. Device administrator (\"android\") is blocked by default in favour of Android Enterprise."

  validation {
    condition     = alltrue([for k in keys(var.platform_restrictions) : contains(["windows", "ios", "android", "androidForWork", "mac"], k)])
    error_message = "platform_restrictions keys must be windows, ios, android, androidForWork or mac."
  }
}

variable "device_limit" {
  type        = number
  default     = 5
  description = "Maximum devices a single user can enroll."

  validation {
    condition     = var.device_limit >= 1 && var.device_limit <= 15
    error_message = "device_limit must be between 1 and 15."
  }
}

variable "device_limit_priority" {
  type    = number
  default = 1

  validation {
    condition     = var.device_limit_priority >= 1
    error_message = "Priority 0 is reserved for the tenant default restriction."
  }
}

variable "restriction_group_ids" {
  type        = list(string)
  description = "User groups the restrictions apply to. Enrollment restrictions evaluate against the enrolling user."
}

variable "device_categories" {
  type        = map(string)
  default     = {}
  description = "Device categories (name => description) offered to users in Company Portal; usable in dynamic group rules via device.deviceCategory."
}
