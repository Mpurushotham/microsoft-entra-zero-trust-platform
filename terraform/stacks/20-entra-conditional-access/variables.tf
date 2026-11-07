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

variable "ca_state" {
  description = "Default state for every policy. Promote individual policies with policy_state_overrides."
  type        = string
  default     = "enabledForReportingButNotEnforced"

  validation {
    condition     = contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], var.ca_state)
    error_message = "ca_state must be enabled, disabled or enabledForReportingButNotEnforced."
  }
}

variable "policy_state_overrides" {
  description = "Per-policy state, keyed by policy number (for example { CA000 = \"enabled\" })."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for s in values(var.policy_state_overrides) : contains(["enabled", "disabled", "enabledForReportingButNotEnforced"], s)])
    error_message = "Override states must be enabled, disabled or enabledForReportingButNotEnforced."
  }
}

variable "enable_risk_policies" {
  description = "Sign-in and user risk policies (CA300, CA301). Requires Microsoft Entra ID P2."
  type        = bool
  default     = true
}

variable "enable_country_block" {
  type    = bool
  default = true
}

variable "enable_workload_identity_policy" {
  description = "CA500 blocks service principals outside trusted locations. Requires Workload Identities Premium."
  type        = bool
  default     = false
}

variable "enable_token_protection" {
  description = "CA600 token protection for administrators (Graph beta)."
  type        = bool
  default     = true
}

variable "admin_sign_in_frequency_hours" {
  type    = number
  default = 4

  validation {
    condition     = var.admin_sign_in_frequency_hours >= 1 && var.admin_sign_in_frequency_hours <= 24
    error_message = "admin_sign_in_frequency_hours must be between 1 and 24."
  }
}
