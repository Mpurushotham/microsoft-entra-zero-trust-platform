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

variable "administrative_units" {
  description = "Administrative units keyed by purpose. Display name becomes <prefix>-<env>-au-<key>."
  type = map(object({
    description               = string
    hidden_membership_enabled = optional(bool, false)
    member_object_ids         = optional(list(string), [])
  }))

  validation {
    condition     = alltrue([for k in keys(var.administrative_units) : can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", k))])
    error_message = "Administrative unit keys must be kebab-case."
  }
}

variable "scoped_role_assignments" {
  description = "Directory roles granted at administrative-unit scope. Use role template IDs; only roles that support AU scope are accepted by Entra ID."
  type = map(object({
    administrative_unit_key = string
    role_template_id        = string
    principal_object_id     = string
  }))
  default = {}

  validation {
    condition     = alltrue([for a in values(var.scoped_role_assignments) : can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", a.role_template_id))])
    error_message = "role_template_id must be a GUID."
  }
}
