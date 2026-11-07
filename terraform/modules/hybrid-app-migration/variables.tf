variable "name_prefix" {
  type    = string
  default = "zt"
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "applications" {
  description = <<-EOT
    AD FS relying parties being moved to Entra enterprise applications, keyed by a short app key.
    protocol: saml | oidc. template_id: Entra app gallery template; SAML apps without one use the
    non-gallery template. adfs_relying_party: the AD FS RP identifier, kept for traceability.
    assignment_groups: static label => group object ID granted the default access role.
    claims_schema: ClaimsSchema entries of a claims mapping policy that replaces AD FS issuance rules.
  EOT
  type = map(object({
    display_name                 = string
    protocol                     = string
    adfs_relying_party           = optional(string)
    template_id                  = optional(string)
    identifier_uris              = optional(list(string), [])
    redirect_uris                = optional(list(string), [])
    homepage_url                 = optional(string)
    logout_url                   = optional(string)
    login_url                    = optional(string)
    relay_state                  = optional(string)
    notification_email_addresses = optional(list(string), [])
    app_role_assignment_required = optional(bool, true)
    assignment_groups            = optional(map(string), {})
    group_membership_claims      = optional(list(string), [])
    hide_from_my_apps            = optional(bool, false)
    owners                       = optional(list(string), [])
    signing_certificate_end_date = optional(string)
    claims_schema = optional(list(object({
      ID            = string
      Source        = string
      SamlClaimType = optional(string)
      JwtClaimType  = optional(string)
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for app in values(var.applications) : contains(["saml", "oidc"], app.protocol)])
    error_message = "Each application protocol must be saml or oidc."
  }

  validation {
    condition     = alltrue([for app in values(var.applications) : app.protocol != "saml" || length(app.identifier_uris) > 0])
    error_message = "SAML applications need at least one identifier_uris entry (the SP entity ID from the AD FS relying party)."
  }

  validation {
    condition     = alltrue([for app in values(var.applications) : alltrue([for uri in app.redirect_uris : startswith(uri, "https://")])])
    error_message = "redirect_uris must use https."
  }

  validation {
    condition = alltrue(flatten([for app in values(var.applications) : [
      for claim in app.group_membership_claims : contains(["None", "SecurityGroup", "DirectoryRole", "ApplicationGroup", "All"], claim)
    ]]))
    error_message = "group_membership_claims values must be None, SecurityGroup, DirectoryRole, ApplicationGroup or All."
  }
}
