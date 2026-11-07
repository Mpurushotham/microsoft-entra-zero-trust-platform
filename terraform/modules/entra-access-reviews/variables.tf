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

variable "start_date" {
  description = "First review date (YYYY-MM-DD)."
  type        = string

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.start_date))
    error_message = "start_date must be YYYY-MM-DD."
  }
}

variable "group_membership_reviews" {
  description = "Recurring reviews of a group's transitive members. Display name becomes <prefix>-<env>-ar-<key>."
  type = map(object({
    group_object_id           = string
    description               = string
    reviewer_group_object_ids = optional(list(string), [])
    reviewer_is_manager       = optional(bool, false)
    fallback_group_object_ids = optional(list(string), [])
    guests_only               = optional(bool, false)
    recurrence_months         = optional(number, 3)
    duration_in_days          = optional(number, 14)
    default_decision          = optional(string, "Deny")
    auto_apply                = optional(bool, true)
  }))
  default = {}

  validation {
    condition     = alltrue([for r in values(var.group_membership_reviews) : r.reviewer_is_manager || length(r.reviewer_group_object_ids) > 0])
    error_message = "Each review needs reviewer groups or reviewer_is_manager = true."
  }

  validation {
    condition     = alltrue([for r in values(var.group_membership_reviews) : contains(["Approve", "Deny", "Recommendation", "None"], r.default_decision)])
    error_message = "default_decision must be Approve, Deny, Recommendation or None."
  }

  validation {
    condition     = alltrue([for r in values(var.group_membership_reviews) : contains([1, 3, 6, 12], r.recurrence_months)])
    error_message = "recurrence_months must be 1, 3, 6 or 12."
  }
}

variable "inactive_guest_review" {
  description = "Tenant-wide review of guests inactive for inactive_days in every Microsoft 365 group, reviewed by group owners."
  type = object({
    enabled                   = optional(bool, true)
    inactive_days             = optional(number, 90)
    fallback_group_object_ids = optional(list(string), [])
    recurrence_months         = optional(number, 3)
    duration_in_days          = optional(number, 14)
  })
  default = {}
}
