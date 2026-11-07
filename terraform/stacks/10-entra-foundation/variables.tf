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

variable "usage_location" {
  type    = string
  default = "US"

  validation {
    condition     = can(regex("^[A-Z]{2}$", var.usage_location))
    error_message = "usage_location must be an ISO 3166-1 alpha-2 country code."
  }
}

variable "break_glass_aliases" {
  type    = list(string)
  default = ["ea-admin-01", "ea-admin-02"]
}

variable "group_owner_object_ids" {
  description = "Owners added to every group created here (for example the deployment service principal and the identity team lead)."
  type        = list(string)
  default     = []
}

variable "additional_groups" {
  description = "Extra groups merged with the baseline set in locals.tf."
  type = map(object({
    description        = string
    dynamic_rule       = optional(string)
    assignable_to_role = optional(bool, false)
    owner_object_ids   = optional(list(string), [])
  }))
  default = {}
}

variable "corporate_egress_ranges" {
  description = "Public egress CIDRs of corporate networks, marked trusted."
  type        = list(string)

  validation {
    condition     = length(var.corporate_egress_ranges) > 0 && alltrue([for r in var.corporate_egress_ranges : can(cidrhost(r, 0))])
    error_message = "Provide at least one valid CIDR."
  }
}

variable "allowed_countries" {
  type    = list(string)
  default = ["US"]

  validation {
    condition     = alltrue([for c in var.allowed_countries : can(regex("^[A-Z]{2}$", c))])
    error_message = "Use ISO 3166-1 alpha-2 country codes."
  }
}

variable "blocked_countries" {
  type    = list(string)
  default = ["KP", "IR", "SY", "CU"]

  validation {
    condition     = alltrue([for c in var.blocked_countries : can(regex("^[A-Z]{2}$", c))])
    error_message = "Use ISO 3166-1 alpha-2 country codes."
  }
}

variable "disable_sms_and_voice" {
  type    = bool
  default = true
}

variable "complete_auth_methods_migration" {
  description = "Set true once legacy MFA/SSPR method settings have been reconciled."
  type        = bool
  default     = false
}

variable "fido2_use_passkey_profiles" {
  type    = bool
  default = true
}

variable "fido2_passkey_types" {
  type    = list(string)
  default = ["deviceBound", "synced"]
}

variable "fido2_attestation_enforced" {
  type    = bool
  default = false
}

variable "enable_custom_security_attributes" {
  description = "Create custom security attribute sets. Needs the Attribute Definition Administrator role and cannot be undone."
  type        = bool
  default     = false
}
