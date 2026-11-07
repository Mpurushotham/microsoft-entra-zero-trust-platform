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

variable "catalogs" {
  description = "Catalogs keyed by purpose. Display name becomes <prefix>-<env>-catalog-<key>."
  type = map(object({
    description        = string
    externally_visible = optional(bool, false)
    resource_group_ids = optional(list(string), [])
  }))
}

variable "access_packages" {
  description = "Access packages keyed by purpose. Display name becomes <prefix>-<env>-ap-<key>. Each package grants membership of the listed groups, which must be resources of its catalog."
  type = map(object({
    catalog_key = string
    description = string
    hidden      = optional(bool, false)
    group_ids   = list(string)
    access_type = optional(string, "Member")
    policy = object({
      requestor_scope_type             = optional(string, "AllExistingDirectoryMemberUsers")
      requestor_group_ids              = optional(list(string), [])
      duration_in_days                 = optional(number, 180)
      extension_enabled                = optional(bool, true)
      approval_required                = optional(bool, true)
      approver_type                    = optional(string, "requestorManager")
      approver_group_ids               = optional(list(string), [])
      backup_approver_group_ids        = optional(list(string), [])
      approval_timeout_in_days         = optional(number, 14)
      requestor_justification_required = optional(bool, true)
      review_enabled                   = optional(bool, true)
      review_frequency                 = optional(string, "quarterly")
      review_type                      = optional(string, "Manager")
      reviewer_group_ids               = optional(list(string), [])
      review_duration_in_days          = optional(number, 14)
      review_timeout_behavior          = optional(string, "removeAccess")
    })
  }))

  validation {
    condition     = alltrue([for p in values(var.access_packages) : contains(keys(var.catalogs), p.catalog_key)])
    error_message = "Every access package catalog_key must reference a key in catalogs."
  }

  validation {
    condition     = alltrue([for p in values(var.access_packages) : contains(["Member", "Owner"], p.access_type)])
    error_message = "access_type must be Member or Owner."
  }

  validation {
    condition = alltrue([for p in values(var.access_packages) : contains([
      "AllExistingDirectoryMemberUsers", "AllExistingDirectorySubjects", "AllExternalSubjects",
      "AllConfiguredConnectedOrganizationSubjects", "AllExistingConnectedOrganizationSubjects",
      "SpecificConnectedOrganizationSubjects", "SpecificDirectorySubjects", "NoSubjects",
    ], p.policy.requestor_scope_type)])
    error_message = "Unsupported requestor_scope_type."
  }

  validation {
    condition     = alltrue([for p in values(var.access_packages) : contains(["requestorManager", "groupMembers"], p.policy.approver_type)])
    error_message = "approver_type must be requestorManager or groupMembers."
  }

  validation {
    condition     = alltrue([for p in values(var.access_packages) : contains(["weekly", "monthly", "quarterly", "halfyearly", "annual"], p.policy.review_frequency)])
    error_message = "review_frequency must be weekly, monthly, quarterly, halfyearly or annual."
  }

  validation {
    condition     = alltrue([for p in values(var.access_packages) : contains(["Self", "Manager", "Reviewers"], p.policy.review_type)])
    error_message = "review_type must be Self, Manager or Reviewers."
  }

  validation {
    condition     = alltrue([for p in values(var.access_packages) : contains(["keepAccess", "removeAccess", "acceptAccessRecommendation"], p.policy.review_timeout_behavior)])
    error_message = "review_timeout_behavior must be keepAccess, removeAccess or acceptAccessRecommendation."
  }
}
