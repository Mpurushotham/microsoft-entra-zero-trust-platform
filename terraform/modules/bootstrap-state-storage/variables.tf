variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_account_name" {
  type = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase letters or digits (globally unique)."
  }
}

variable "container_name" {
  type    = string
  default = "tfstate"

  validation {
    condition     = can(regex("^[a-z0-9](?:[a-z0-9-]{1,61}[a-z0-9])$", var.container_name))
    error_message = "container_name must be 3-63 lowercase letters, digits or hyphens."
  }
}

variable "replication_type" {
  type    = string
  default = "ZRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS", "GZRS", "RAGRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be one of LRS, ZRS, GRS, GZRS, RAGRS, RAGZRS."
  }
}

variable "soft_delete_retention_days" {
  type    = number
  default = 30

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 365
    error_message = "soft_delete_retention_days must be between 7 and 365."
  }
}

variable "public_network_access" {
  type        = string
  description = "Enabled keeps GitHub-hosted runners working (data plane still requires Entra ID auth). Use Disabled with a private endpoint and self-hosted runners."
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "public_network_access must be Enabled or Disabled."
  }
}

variable "network_default_action" {
  type        = string
  description = "Deny requires allowed_ip_ranges or private connectivity for every runner and operator."
  default     = "Allow"

  validation {
    condition     = contains(["Allow", "Deny"], var.network_default_action)
    error_message = "network_default_action must be Allow or Deny."
  }
}

variable "allowed_ip_ranges" {
  type    = set(string)
  default = []

  validation {
    condition     = alltrue([for ip in var.allowed_ip_ranges : can(cidrhost(strcontains(ip, "/") ? ip : "${ip}/32", 0))])
    error_message = "allowed_ip_ranges must contain IPv4 addresses or CIDR ranges."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Set after stack 70 exists to stream state blob access logs to Microsoft Sentinel."
  default     = null
}

variable "delete_lock_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
