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

variable "scope_tags" {
  type = map(object({
    description      = string
    device_group_ids = optional(list(string), [])
  }))
  default     = {}
  description = "Scope tags keyed by short name. Devices in device_group_ids are tagged automatically."
}

variable "role_assignments" {
  type = map(object({
    role_display_name = string
    member_group_ids  = list(string)
    scope_group_ids   = optional(list(string), [])
    scope_type        = optional(string, "resourceScope")
    scope_tag_keys    = optional(list(string), [])
  }))
  default     = {}
  description = "Intune role assignments keyed by short name. role_display_name must match a built-in or custom Intune role exactly."

  validation {
    condition     = alltrue([for a in values(var.role_assignments) : contains(["resourceScope", "allDevices", "allLicensedUsers", "allDevicesAndLicensedUsers"], a.scope_type)])
    error_message = "scope_type must be resourceScope, allDevices, allLicensedUsers or allDevicesAndLicensedUsers."
  }

  validation {
    condition     = alltrue([for a in values(var.role_assignments) : a.scope_type != "resourceScope" || length(a.scope_group_ids) > 0])
    error_message = "resourceScope assignments need at least one scope_group_ids entry."
  }
}
