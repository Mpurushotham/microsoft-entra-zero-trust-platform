variable "name_prefix" {
  type    = string
  default = "zt"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,7}$", var.name_prefix))
    error_message = "name_prefix must be 2-8 lowercase letters or digits, starting with a letter."
  }
}

variable "location" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as westeurope."
  }
}

variable "environments" {
  type    = set(string)
  default = ["dev", "prod"]

  validation {
    condition     = length(var.environments) > 0 && alltrue([for e in var.environments : contains(["dev", "prod"], e)])
    error_message = "environments may only contain dev and prod."
  }
}

variable "enabled_stacks" {
  type        = set(string)
  description = "Stacks whose Microsoft Graph and Azure permissions are granted to the pipeline identities."
  default = [
    "10-entra-foundation",
    "20-entra-conditional-access",
    "30-entra-governance",
    "40-hybrid-migration",
    "50-intune-foundation",
    "60-intune-autopilot-zero-touch",
    "70-security-operations",
  ]

  validation {
    condition = alltrue([for s in var.enabled_stacks : contains([
      "10-entra-foundation",
      "20-entra-conditional-access",
      "30-entra-governance",
      "40-hybrid-migration",
      "50-intune-foundation",
      "60-intune-autopilot-zero-touch",
      "70-security-operations",
    ], s)])
    error_message = "enabled_stacks contains an unknown stack name."
  }
}

variable "github_repository" {
  type    = string
  default = "Mpurushotham/microsoft-entra-zero-trust-platform"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must be in owner/name form."
  }
}

variable "github_default_branch" {
  type    = string
  default = "main"
}

variable "operator_object_ids" {
  type        = set(string)
  description = "Entra object IDs of the platform owners: app registration owners and state break-glass access."

  validation {
    condition = length(var.operator_object_ids) > 0 && alltrue([
      for id in var.operator_object_ids : can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", id))
    ])
    error_message = "operator_object_ids must contain at least one Entra object ID (GUID)."
  }
}

variable "state_resource_group_name" {
  type    = string
  default = null
}

variable "state_storage_account_name" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.state_storage_account_name))
    error_message = "state_storage_account_name must be 3-24 lowercase letters or digits (globally unique)."
  }
}

variable "state_replication_type" {
  type    = string
  default = "GZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.state_replication_type)
    error_message = "state_replication_type must be one of LRS, ZRS, GRS, GZRS, RAGRS, RAGZRS."
  }
}

variable "state_public_network_access" {
  type    = string
  default = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.state_public_network_access)
    error_message = "state_public_network_access must be Enabled or Disabled."
  }
}

variable "state_network_default_action" {
  type    = string
  default = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.state_network_default_action)
    error_message = "state_network_default_action must be Allow or Deny."
  }
}

variable "state_allowed_ip_ranges" {
  type    = set(string)
  default = []
}

variable "state_log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the stack 70 workspace; leave null on the first run."
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
