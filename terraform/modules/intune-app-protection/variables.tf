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

variable "protection_level" {
  type        = number
  default     = 2
  description = "Microsoft App protection data protection framework level: 1 enterprise basic, 2 enterprise enhanced, 3 enterprise high."

  validation {
    condition     = contains([1, 2, 3], var.protection_level)
    error_message = "protection_level must be 1, 2 or 3."
  }
}

variable "platforms" {
  type    = set(string)
  default = ["ios", "android"]

  validation {
    condition     = alltrue([for p in var.platforms : contains(["ios", "android"], p)])
    error_message = "platforms may only contain ios and android."
  }
}

variable "ios_bundle_ids" {
  type        = list(string)
  default     = []
  description = "Overrides the default core Microsoft 365 iOS bundle IDs."
}

variable "android_package_ids" {
  type        = list(string)
  default     = []
  description = "Overrides the default core Microsoft 365 Android package IDs."
}

variable "minimum_os_versions" {
  type = object({
    ios     = optional(string, "17.0")
    android = optional(string, "12.0")
  })
  default     = {}
  description = "Below these versions the app blocks access to work data."
}

variable "include_group_ids" {
  type        = list(string)
  description = "User groups targeted by the policies. App protection targets users, not devices."
}

variable "exclude_group_ids" {
  type    = list(string)
  default = []
}
