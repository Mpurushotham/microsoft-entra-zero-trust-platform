variable "role_eligibilities" {
  description = "PIM-eligible directory role assignments (principal must activate). Principal can be a user or a role-assignable group."
  type = map(object({
    principal_object_id = string
    role_template_id    = string
    directory_scope_id  = optional(string, "/")
    justification       = optional(string, "Eligible assignment managed in source control")
  }))
  default = {}

  validation {
    condition     = alltrue([for e in values(var.role_eligibilities) : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", e.role_template_id))])
    error_message = "role_template_id must be a directory role template GUID."
  }
}

variable "role_assignments" {
  description = "Active directory role assignments. Use only for role-assignable groups whose membership is itself just-in-time (PIM for Groups)."
  type = map(object({
    principal_object_id = string
    role_template_id    = string
    directory_scope_id  = optional(string, "/")
  }))
  default = {}

  validation {
    condition     = alltrue([for e in values(var.role_assignments) : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", e.role_template_id))])
    error_message = "role_template_id must be a directory role template GUID."
  }
}

variable "group_policies" {
  description = "PIM for Groups member-role policy per privileged access group."
  type = map(object({
    group_object_id                   = string
    activation_maximum_duration       = optional(string, "PT4H")
    require_approval                  = optional(bool, false)
    approver_group_object_ids         = optional(list(string), [])
    require_multifactor_on_activation = optional(bool, true)
    require_justification             = optional(bool, true)
    require_ticket_info               = optional(bool, false)
    eligible_expire_after             = optional(string, "P365D")
    active_expire_after               = optional(string, "P15D")
    notification_recipients           = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for p in values(var.group_policies) : !p.require_approval || length(p.approver_group_object_ids) > 0])
    error_message = "require_approval needs at least one approver group."
  }

  validation {
    condition     = alltrue([for p in values(var.group_policies) : contains(["P15D", "P30D", "P90D", "P180D", "P365D"], p.eligible_expire_after) && contains(["P15D", "P30D", "P90D", "P180D", "P365D"], p.active_expire_after)])
    error_message = "expire_after values must be one of P15D, P30D, P90D, P180D, P365D."
  }

  validation {
    condition     = alltrue([for p in values(var.group_policies) : can(regex("^PT([1-9]|1[0-9]|2[0-3])H(30M)?$|^PT30M$|^P1D$", p.activation_maximum_duration))])
    error_message = "activation_maximum_duration must be PT30M to PT23H30M in 30-minute steps, or P1D."
  }
}

variable "group_eligible_members" {
  description = "Eligible (just-in-time) members of privileged access groups."
  type = map(object({
    group_object_id     = string
    principal_object_id = string
    duration            = optional(string, "P365D")
    justification       = optional(string, "Eligible membership managed in source control")
  }))
  default = {}
}

variable "directory_role_policies" {
  description = "PIM settings per directory role (activation duration, MFA, justification, approval, eligibility expiry), applied through Microsoft Graph."
  type = map(object({
    role_template_id                  = string
    activation_maximum_duration       = optional(string, "PT4H")
    require_multifactor_on_activation = optional(bool, true)
    require_justification             = optional(bool, true)
    require_ticket_info               = optional(bool, false)
    require_approval                  = optional(bool, false)
    approver_group_object_ids         = optional(list(string), [])
    eligible_maximum_duration         = optional(string, "P365D")
  }))
  default = {}

  validation {
    condition     = alltrue([for p in values(var.directory_role_policies) : !p.require_approval || length(p.approver_group_object_ids) > 0])
    error_message = "require_approval needs at least one approver group."
  }
}
