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

variable "policies" {
  type    = set(string)
  default = ["credential_guard", "os_hardening"]

  validation {
    condition     = alltrue([for p in var.policies : contains(["credential_guard", "os_hardening"], p)])
    error_message = "policies may only contain credential_guard and os_hardening."
  }
}

variable "credential_guard_uefi_lock" {
  type        = bool
  default     = true
  description = "Lock Credential Guard in UEFI so it cannot be disabled remotely. Turning it off later requires physical access."
}

variable "vbs_require_dma_protection" {
  type        = bool
  default     = false
  description = "Require DMA protection in addition to Secure Boot for VBS. Only enable when the fleet hardware supports it."
}

variable "dma_guard_policy" {
  type        = string
  default     = "block_all"
  description = "Kernel DMA Protection enumeration policy for external devices that are incompatible with DMA remapping."

  validation {
    condition     = contains(["block_all", "after_login", "allow_all"], var.dma_guard_policy)
    error_message = "dma_guard_policy must be block_all, after_login or allow_all."
  }
}

variable "assignments" {
  type = map(object({
    include_group_ids = list(string)
    exclude_group_ids = optional(list(string), [])
  }))
  default     = {}
  description = "Group assignments keyed by policy key."
}
