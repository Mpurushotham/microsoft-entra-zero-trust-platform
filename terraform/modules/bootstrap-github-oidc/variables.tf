variable "display_name" {
  type = string

  validation {
    condition     = length(trimspace(var.display_name)) > 0
    error_message = "display_name must not be empty."
  }
}

variable "description" {
  type    = string
  default = null
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in owner/name form."

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must be in owner/name form."
  }
}

variable "github_subjects" {
  type        = set(string)
  description = "Subject suffixes after repo:<owner>/<name>:, for example environment:prod, pull_request or ref:refs/heads/main."

  validation {
    condition     = length(var.github_subjects) > 0 && length(var.github_subjects) <= 20
    error_message = "Provide between 1 and 20 subjects (Entra limit for federated credentials per application)."
  }

  validation {
    condition = alltrue([
      for s in var.github_subjects : can(regex("^(environment:[A-Za-z0-9._-]+|pull_request|ref:refs/(heads|tags)/.+)$", s))
    ])
    error_message = "Each subject must be environment:<name>, pull_request or ref:refs/heads|tags/<name>."
  }
}

variable "graph_app_roles" {
  type        = set(string)
  description = "Microsoft Graph application permission values (for example Policy.Read.All) granted with admin consent."
  default     = []

  validation {
    condition     = alltrue([for r in var.graph_app_roles : can(regex("^[A-Za-z]+(\\.[A-Za-z]+)+$", r))])
    error_message = "graph_app_roles must be Microsoft Graph permission values such as Group.ReadWrite.All."
  }
}

variable "directory_role_template_ids" {
  type        = set(string)
  description = "Built-in Entra directory role template IDs assigned tenant-wide to the service principal."
  default     = []
}

variable "azure_role_assignments" {
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  description = "Azure RBAC assignments keyed by a stable name."
  default     = {}
}

variable "owner_object_ids" {
  type        = set(string)
  description = "Object IDs of the humans accountable for the application registration."

  validation {
    condition     = length(var.owner_object_ids) > 0
    error_message = "At least one owner is required so the registration is never orphaned."
  }
}

variable "service_management_reference" {
  type    = string
  default = null
}
