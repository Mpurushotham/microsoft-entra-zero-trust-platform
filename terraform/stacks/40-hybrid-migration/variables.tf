variable "name_prefix" {
  type    = string
  default = "zt"

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

variable "migration_waves" {
  type    = list(string)
  default = ["pilot", "wave1", "wave2", "all"]
}

variable "enabled_waves" {
  description = "Waves currently attached to staged rollout. Append one wave per change after the previous wave passes its exit criteria."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for w in var.enabled_waves : contains(var.migration_waves, w)])
    error_message = "Every enabled wave must be listed in migration_waves."
  }
}

variable "staged_features" {
  description = "Graph stagedFeatureName values. Add certificateBasedAuthentication when AD FS issued smart-card or certificate sign-in."
  type        = set(string)
  default     = ["passwordHashSync", "seamlessSso"]
}

variable "staged_rollout_enabled" {
  type    = bool
  default = true
}

variable "wave_group_owners" {
  description = "Object IDs of the migration team owners for the wave groups."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.wave_group_owners : can(regex("^[0-9a-fA-F-]{36}$", id))])
    error_message = "wave_group_owners must be object IDs (GUIDs)."
  }
}

variable "migrated_applications" {
  description = <<-EOT
    AD FS relying parties to recreate as Entra enterprise applications. Produce the starting point with
    scripts/hybrid-migration/Get-ADFSRelyingPartyInventory.ps1. assign_to_waves grants access to the
    wave groups of this stack; assignment_group_display_names references groups owned by other stacks.
  EOT
  type = map(object({
    display_name                   = string
    protocol                       = string
    adfs_relying_party             = optional(string)
    template_id                    = optional(string)
    identifier_uris                = optional(list(string), [])
    redirect_uris                  = optional(list(string), [])
    homepage_url                   = optional(string)
    logout_url                     = optional(string)
    login_url                      = optional(string)
    relay_state                    = optional(string)
    notification_email_addresses   = optional(list(string), [])
    app_role_assignment_required   = optional(bool, true)
    assign_to_waves                = optional(list(string), [])
    assignment_group_display_names = optional(list(string), [])
    group_membership_claims        = optional(list(string), [])
    hide_from_my_apps              = optional(bool, false)
    signing_certificate_end_date   = optional(string)
    claims_schema = optional(list(object({
      ID            = string
      Source        = string
      SamlClaimType = optional(string)
      JwtClaimType  = optional(string)
    })), [])
  }))
  default = {}
}

variable "cloud_managed_group_ids" {
  description = <<-EOT
    Object IDs of AD-synced groups whose source of authority is converted to the cloud
    (onPremisesSyncBehavior.isCloudManaged = true). Once converted, sync stops writing to them and they
    are managed in Entra. Pair with Cloud Sync group provisioning to AD if on-prem apps still need them.
  EOT
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.cloud_managed_group_ids : can(regex("^[0-9a-fA-F-]{36}$", id))])
    error_message = "cloud_managed_group_ids must be object IDs (GUIDs)."
  }
}
