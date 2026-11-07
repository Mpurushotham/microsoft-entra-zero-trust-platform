variable "name_prefix" {
  type = string

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

variable "excluded_group_ids" {
  description = "Groups excluded from the registration campaign (typically the emergency access group)."
  type        = list(string)
  default     = []
}

variable "fido2" {
  description = "Passkey (FIDO2) settings. With use_passkey_profiles the default passkey profile carries attestation and key restrictions; otherwise the legacy top-level properties are used."
  type = object({
    enabled                   = optional(bool, true)
    include_target_ids        = optional(list(string), ["all_users"])
    self_service_registration = optional(bool, true)
    use_passkey_profiles      = optional(bool, true)
    passkey_types             = optional(list(string), ["deviceBound", "synced"])
    attestation_enforced      = optional(bool, false)
    key_restrictions_enforced = optional(bool, false)
    key_restriction_type      = optional(string, "allow")
    key_restriction_aaguids   = optional(list(string), [])
  })
  default = {}

  validation {
    condition     = contains(["allow", "block"], var.fido2.key_restriction_type)
    error_message = "key_restriction_type must be allow or block."
  }

  validation {
    condition     = length(var.fido2.passkey_types) > 0 && alltrue([for t in var.fido2.passkey_types : contains(["deviceBound", "synced"], t)])
    error_message = "passkey_types must contain deviceBound and/or synced."
  }
}

variable "microsoft_authenticator" {
  description = "Microsoft Authenticator settings. Number matching is always enforced by Entra ID for push and is no longer configurable."
  type = object({
    enabled                  = optional(bool, true)
    include_target_ids       = optional(list(string), ["all_users"])
    authentication_mode      = optional(string, "any")
    show_application_name    = optional(bool, true)
    show_geographic_location = optional(bool, true)
    software_oath_enabled    = optional(bool, false)
  })
  default = {}

  validation {
    condition     = contains(["any", "push", "deviceBasedPush"], var.microsoft_authenticator.authentication_mode)
    error_message = "authentication_mode must be any, push or deviceBasedPush."
  }
}

variable "temporary_access_pass" {
  type = object({
    enabled                     = optional(bool, true)
    include_target_ids          = optional(list(string), ["all_users"])
    default_lifetime_in_minutes = optional(number, 60)
    minimum_lifetime_in_minutes = optional(number, 60)
    maximum_lifetime_in_minutes = optional(number, 480)
    default_length              = optional(number, 12)
    is_usable_once              = optional(bool, true)
  })
  default = {}

  validation {
    condition = (
      var.temporary_access_pass.minimum_lifetime_in_minutes >= 10 &&
      var.temporary_access_pass.maximum_lifetime_in_minutes <= 43200 &&
      var.temporary_access_pass.minimum_lifetime_in_minutes <= var.temporary_access_pass.default_lifetime_in_minutes &&
      var.temporary_access_pass.default_lifetime_in_minutes <= var.temporary_access_pass.maximum_lifetime_in_minutes
    )
    error_message = "TAP lifetimes must satisfy 10 <= minimum <= default <= maximum <= 43200 minutes."
  }

  validation {
    condition     = var.temporary_access_pass.default_length >= 8 && var.temporary_access_pass.default_length <= 48
    error_message = "TAP default_length must be between 8 and 48."
  }
}

variable "disable_sms" {
  description = "Disable SMS as an authentication method. Microsoft classes SMS and voice as the weakest MFA methods."
  type        = bool
  default     = true
}

variable "disable_voice" {
  type    = bool
  default = true
}

variable "registration_campaign" {
  description = "Nudge users without a strong method to register one at sign-in."
  type = object({
    enabled                 = optional(bool, true)
    snooze_duration_in_days = optional(number, 1)
    targeted_method         = optional(string, "microsoftAuthenticator")
  })
  default = {}

  validation {
    condition     = var.registration_campaign.snooze_duration_in_days >= 0 && var.registration_campaign.snooze_duration_in_days <= 14
    error_message = "snooze_duration_in_days must be between 0 and 14."
  }

  validation {
    condition     = contains(["microsoftAuthenticator", "Fido2"], var.registration_campaign.targeted_method)
    error_message = "targeted_method must be microsoftAuthenticator or Fido2."
  }
}

variable "complete_policy_migration" {
  description = "Mark the legacy MFA/SSPR method settings as migrated, so only the Authentication methods policy applies. Only set after the legacy settings have been reconciled."
  type        = bool
  default     = false
}

variable "authentication_strengths" {
  description = "Custom authentication strengths keyed by purpose. Display name becomes <prefix>-<env>-as-<key>."
  type = map(object({
    description          = string
    allowed_combinations = list(string)
  }))
  default = {}
}
