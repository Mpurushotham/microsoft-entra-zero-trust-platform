variable "default_state" {
  description = "State for policies that do not set their own. Keep report-only until sign-in logs and the What If tool confirm impact."
  type        = string
  default     = "enabledForReportingButNotEnforced"

  validation {
    condition     = contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], var.default_state)
    error_message = "default_state must be enabled, disabled or enabledForReportingButNotEnforced."
  }
}

variable "emergency_access_group_ids" {
  description = "Groups excluded from every policy in this module. Must contain the emergency access group."
  type        = list(string)

  validation {
    condition     = length(var.emergency_access_group_ids) > 0
    error_message = "At least one emergency access group must be excluded from Conditional Access."
  }
}

variable "policies" {
  description = "Conditional Access policies keyed by policy number (for example CA001). Shape mirrors azuread_conditional_access_policy."
  type = map(object({
    display_name = string
    state        = optional(string)

    client_app_types                     = optional(list(string), ["all"])
    authentication_flow_transfer_methods = optional(list(string))
    sign_in_risk_levels                  = optional(list(string))
    user_risk_levels                     = optional(list(string))
    insider_risk_levels                  = optional(string)
    service_principal_risk_levels        = optional(list(string))

    included_users  = optional(list(string), [])
    excluded_users  = optional(list(string), [])
    included_groups = optional(list(string), [])
    excluded_groups = optional(list(string), [])
    included_roles  = optional(list(string), [])
    excluded_roles  = optional(list(string), [])
    included_guests_or_external_users = optional(object({
      types                   = list(string)
      external_tenant_kind    = optional(string, "all")
      external_tenant_members = optional(list(string))
    }))
    excluded_guests_or_external_users = optional(object({
      types                   = list(string)
      external_tenant_kind    = optional(string, "all")
      external_tenant_members = optional(list(string))
    }))

    included_applications       = optional(list(string))
    excluded_applications       = optional(list(string), [])
    included_user_actions       = optional(list(string))
    included_service_principals = optional(list(string))
    excluded_service_principals = optional(list(string), [])

    device_filter = optional(object({
      mode = string
      rule = string
    }))
    included_locations = optional(list(string))
    excluded_locations = optional(list(string), [])
    included_platforms = optional(list(string))
    excluded_platforms = optional(list(string), [])

    grant = optional(object({
      operator                          = optional(string, "OR")
      built_in_controls                 = optional(list(string), [])
      authentication_strength_policy_id = optional(string)
      terms_of_use                      = optional(list(string), [])
    }))

    session = optional(object({
      application_enforced_restrictions_enabled = optional(bool)
      cloud_app_security_policy                 = optional(string)
      disable_resilience_defaults               = optional(bool)
      persistent_browser_mode                   = optional(string)
      sign_in_frequency                         = optional(number)
      sign_in_frequency_period                  = optional(string)
      sign_in_frequency_interval                = optional(string)
      sign_in_frequency_authentication_type     = optional(string)
    }))
  }))

  validation {
    condition     = alltrue([for p in values(var.policies) : p.state == null || contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], coalesce(p.state, "disabled"))])
    error_message = "Policy state must be enabled, disabled or enabledForReportingButNotEnforced."
  }

  validation {
    condition     = alltrue([for p in values(var.policies) : (p.included_applications == null) != (p.included_user_actions == null)])
    error_message = "Each policy needs exactly one of included_applications or included_user_actions."
  }

  validation {
    condition     = alltrue([for p in values(var.policies) : p.grant != null || p.session != null])
    error_message = "Each policy needs a grant or a session control."
  }

  validation {
    condition     = alltrue([for p in values(var.policies) : p.grant == null ? true : contains(["AND", "OR"], p.grant.operator)])
    error_message = "grant.operator must be AND or OR."
  }
}

variable "token_protection_policies" {
  description = "Token protection (secure sign-in session) policies. Created through Microsoft Graph beta because v1.0 and azuread do not expose secureSignInSession."
  type = map(object({
    display_name          = string
    state                 = optional(string)
    included_roles        = optional(list(string), [])
    included_groups       = optional(list(string), [])
    included_users        = optional(list(string), [])
    excluded_groups       = optional(list(string), [])
    included_applications = list(string)
    included_platforms    = optional(list(string), ["windows"])
  }))
  default = {}

  validation {
    condition     = alltrue([for p in values(var.token_protection_policies) : p.state == null || contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], coalesce(p.state, "disabled"))])
    error_message = "Policy state must be enabled, disabled or enabledForReportingButNotEnforced."
  }
}
