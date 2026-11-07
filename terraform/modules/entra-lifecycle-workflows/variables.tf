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

variable "workflows" {
  description = "Lifecycle workflows keyed by purpose. Display name becomes <prefix>-<env>-lcw-<key>."
  type = map(object({
    category           = string
    description        = string
    is_enabled         = optional(bool, true)
    scheduling_enabled = optional(bool, false)
    scope_rule         = string
    trigger = object({
      time_based_attribute = optional(string)
      offset_in_days       = optional(number, 0)
      changed_attributes   = optional(list(string))
    })
    tasks = list(object({
      display_name       = string
      description        = optional(string, "")
      task_definition_id = string
      continue_on_error  = optional(bool, false)
      is_enabled         = optional(bool, true)
      arguments          = optional(map(string), {})
    }))
  }))

  validation {
    condition     = alltrue([for w in values(var.workflows) : contains(["joiner", "mover", "leaver"], w.category)])
    error_message = "category must be joiner, mover or leaver."
  }

  validation {
    condition     = alltrue([for w in values(var.workflows) : (w.trigger.time_based_attribute == null) != (w.trigger.changed_attributes == null)])
    error_message = "Each trigger needs exactly one of time_based_attribute or changed_attributes."
  }

  validation {
    condition     = alltrue([for w in values(var.workflows) : w.trigger.time_based_attribute == null || contains(["employeeHireDate", "employeeLeaveDateTime", "createdDateTime"], coalesce(w.trigger.time_based_attribute, "createdDateTime"))])
    error_message = "time_based_attribute must be employeeHireDate, employeeLeaveDateTime or createdDateTime."
  }

  validation {
    condition     = alltrue([for w in values(var.workflows) : w.trigger.offset_in_days >= -180 && w.trigger.offset_in_days <= 180])
    error_message = "offset_in_days must be between -180 and 180."
  }

  validation {
    condition     = alltrue([for w in values(var.workflows) : length(w.tasks) > 0 && length(w.tasks) == length(distinct([for t in w.tasks : t.display_name]))])
    error_message = "Each workflow needs at least one task, and task display names must be unique within it."
  }
}
