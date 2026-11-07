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

variable "groups" {
  description = "Security groups keyed by purpose. Display name becomes <prefix>-<env>-<key>."
  type = map(object({
    description        = string
    dynamic_rule       = optional(string)
    assignable_to_role = optional(bool, false)
    owner_object_ids   = optional(list(string), [])
  }))

  validation {
    condition     = alltrue([for k in keys(var.groups) : can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", k))])
    error_message = "Group keys must be kebab-case."
  }

  validation {
    condition     = alltrue([for g in values(var.groups) : !(g.assignable_to_role && g.dynamic_rule != null)])
    error_message = "Role-assignable groups cannot use dynamic membership."
  }
}

variable "default_owner_object_ids" {
  description = "Owners added to every group, typically the deployment identity so it keeps management rights."
  type        = list(string)
  default     = []
}
