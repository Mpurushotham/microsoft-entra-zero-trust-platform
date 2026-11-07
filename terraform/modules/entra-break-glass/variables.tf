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

variable "account_aliases" {
  description = "Mail nicknames of the emergency access accounts. Avoid names that reveal the account's purpose or tie it to a person."
  type        = list(string)
  default     = ["ea-admin-01", "ea-admin-02"]

  validation {
    condition     = length(var.account_aliases) >= 2 && length(var.account_aliases) == length(distinct(var.account_aliases))
    error_message = "Microsoft recommends at least two distinct emergency access accounts."
  }

  validation {
    condition     = alltrue([for a in var.account_aliases : can(regex("^[a-z0-9][a-z0-9.-]{2,40}$", a))])
    error_message = "Aliases must be 3-41 lowercase characters: letters, digits, dot or hyphen."
  }
}

variable "usage_location" {
  type    = string
  default = "US"

  validation {
    condition     = can(regex("^[A-Z]{2}$", var.usage_location))
    error_message = "usage_location must be an ISO 3166-1 alpha-2 country code."
  }
}

variable "password_length" {
  type    = number
  default = 64

  validation {
    condition     = var.password_length >= 32 && var.password_length <= 256
    error_message = "password_length must be between 32 and 256 (Entra ID maximum)."
  }
}

variable "assign_global_administrator" {
  description = "Permanently assign Global Administrator, as Microsoft's emergency access guidance requires. Disable only while bootstrapping a tenant where the role is assigned out of band."
  type        = bool
  default     = true
}
