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

variable "pim_eligible_members" {
  description = "UPNs eligible to activate membership of each Tier-1/Tier-2 PIM group, keyed by group key (for example pim-security-administrators)."
  type        = map(list(string))
  default     = {}
}

variable "tier0_activation_hours" {
  type    = number
  default = 2

  validation {
    condition     = var.tier0_activation_hours >= 1 && var.tier0_activation_hours <= 8
    error_message = "tier0_activation_hours must be between 1 and 8."
  }
}

variable "tier1_activation_hours" {
  type    = number
  default = 4

  validation {
    condition     = var.tier1_activation_hours >= 1 && var.tier1_activation_hours <= 23
    error_message = "tier1_activation_hours must be between 1 and 23."
  }
}

variable "pim_notification_recipients" {
  description = "Mailboxes notified on every privileged group activation (for example the SOC distribution list)."
  type        = list(string)
  default     = []
}

variable "access_review_start_date" {
  type    = string
  default = "2027-01-04"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.access_review_start_date))
    error_message = "access_review_start_date must be YYYY-MM-DD."
  }
}

variable "lifecycle_scope_rule" {
  description = "Users in scope for joiner/mover/leaver workflows."
  type        = string
  default     = "(employeeType eq 'Employee')"
}

variable "lifecycle_scheduling_enabled" {
  description = "Let the scheduler run workflows. Keep false until on-demand runs have been checked."
  type        = bool
  default     = false
}

variable "leaver_delete_after_days" {
  type    = number
  default = 7

  validation {
    condition     = var.leaver_delete_after_days >= 1 && var.leaver_delete_after_days <= 180
    error_message = "leaver_delete_after_days must be between 1 and 180."
  }
}
