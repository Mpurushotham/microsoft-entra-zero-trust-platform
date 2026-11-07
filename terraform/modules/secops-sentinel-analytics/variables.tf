variable "log_analytics_workspace_id" {
  type        = string
  description = "Workspace ID output by Sentinel onboarding, so rules are created after onboarding."
}

variable "name_prefix" {
  type    = string
  default = "zt"
}

variable "break_glass_upns" {
  type = set(string)

  validation {
    condition     = length(var.break_glass_upns) > 0 && alltrue([for u in var.break_glass_upns : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", u))])
    error_message = "break_glass_upns must contain at least one user principal name."
  }
}

variable "trusted_automation_names" {
  type        = set(string)
  description = "Service principal display names allowed to change Conditional Access (the pipeline apply identities). Changes by anyone else alert."
  default     = []
}

variable "business_hours" {
  type = object({
    start_hour       = number
    end_hour         = number
    utc_offset_hours = number
    workdays         = list(number)
  })
  description = "Local working hours for PIM activation monitoring. workdays uses KQL dayofweek numbering (0 = Sunday)."
  default = {
    start_hour       = 7
    end_hour         = 19
    utc_offset_hours = 0
    workdays         = [1, 2, 3, 4, 5]
  }

  validation {
    condition = (
      var.business_hours.start_hour >= 0 && var.business_hours.start_hour < var.business_hours.end_hour && var.business_hours.end_hour <= 24 &&
      var.business_hours.utc_offset_hours >= -12 && var.business_hours.utc_offset_hours <= 14 &&
      alltrue([for d in var.business_hours.workdays : d >= 0 && d <= 6])
    )
    error_message = "business_hours needs 0 <= start_hour < end_hour <= 24, utc_offset_hours in -12..14 and workdays in 0..6."
  }
}

variable "mfa_fatigue_threshold" {
  type        = number
  description = "Denied or unanswered MFA prompts for one user within an hour before alerting."
  default     = 5

  validation {
    condition     = var.mfa_fatigue_threshold >= 2
    error_message = "mfa_fatigue_threshold must be at least 2."
  }
}

variable "disabled_rules" {
  type        = set(string)
  description = "Rule keys to deploy disabled, for example while tuning in dev."
  default     = []
}
