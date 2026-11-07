locals {
  name = "${var.name_prefix}-${var.environment}"

  # Directory role template IDs (Microsoft Entra built-in roles reference).
  roles = {
    global_administrator                    = "62e90394-69f5-4237-9190-012177145e10"
    application_administrator               = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
    authentication_administrator            = "c4e39bd9-1100-46d3-8c65-fb160da0071f"
    billing_administrator                   = "b0f54661-2d74-4c50-afa3-1ec803f12efe"
    cloud_application_administrator         = "158c047a-c907-4556-b7ef-446551a6b5f7"
    conditional_access_administrator        = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
    exchange_administrator                  = "29232cdf-9323-42fd-ade2-1d097af3e4de"
    helpdesk_administrator                  = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
    password_administrator                  = "966707d0-3269-4727-9be2-8c3a10f19b9d"
    privileged_authentication_administrator = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
    privileged_role_administrator           = "e8611ab8-c189-46e8-94e1-60213ab1f814"
    security_administrator                  = "194ae4cb-b126-40b2-bd5b-6091b380977d"
    sharepoint_administrator                = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
    user_administrator                      = "fe930be7-5e62-47db-91af-98c3a49a38b1"
    intune_administrator                    = "3a2c62db-5318-420d-8d74-23affee5d9d5"
    hybrid_identity_administrator           = "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2"
    authentication_policy_administrator     = "0526716b-113d-4c15-b2c8-68e3c22b9f80"
    global_reader                           = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
    directory_synchronization_accounts      = "d29b2b05-8046-44ba-8758-1e26182fcf32"
  }

  # Microsoft's "Require MFA for administrators" template roles, plus roles that control identity and devices.
  privileged_roles = [
    local.roles.global_administrator,
    local.roles.application_administrator,
    local.roles.authentication_administrator,
    local.roles.billing_administrator,
    local.roles.cloud_application_administrator,
    local.roles.conditional_access_administrator,
    local.roles.exchange_administrator,
    local.roles.helpdesk_administrator,
    local.roles.password_administrator,
    local.roles.privileged_authentication_administrator,
    local.roles.privileged_role_administrator,
    local.roles.security_administrator,
    local.roles.sharepoint_administrator,
    local.roles.user_administrator,
    local.roles.intune_administrator,
    local.roles.hybrid_identity_administrator,
    local.roles.authentication_policy_administrator,
  ]

  apps = {
    azure_management  = "797f4846-ba00-4fd7-ba43-dac1f8f63013"
    exchange_online   = "00000002-0000-0ff1-ce00-000000000000"
    sharepoint_online = "00000003-0000-0ff1-ce00-000000000000"
    teams_services    = "cc15fd57-2c6c-4117-a88c-83b1d56b4bbe"
  }

  # Built-in "Multifactor authentication" strength.
  strength_mfa = "/policies/authenticationStrengthPolicies/00000000-0000-0000-0000-000000000002"

  all_guest_types = [
    "internalGuest",
    "b2bCollaborationGuest",
    "b2bCollaborationMember",
    "b2bDirectConnectUser",
    "otherExternalUser",
    "serviceProvider",
  ]

  exclude_guests = {
    types = local.all_guest_types
  }

  baseline_policies = {
    CA000 = {
      display_name          = "${local.name}-CA000-Global-BaseProtection-AllApps-AnyPlatform-Block-LegacyAuthentication"
      client_app_types      = ["exchangeActiveSync", "other"]
      included_users        = ["All"]
      included_applications = ["All"]
      grant                 = { built_in_controls = ["block"] }
    }
    CA001 = {
      display_name                         = "${local.name}-CA001-Global-BaseProtection-AllApps-AnyPlatform-Block-DeviceCodeAndAuthTransfer"
      authentication_flow_transfer_methods = ["deviceCodeFlow", "authenticationTransfer"]
      included_users                       = ["All"]
      included_applications                = ["All"]
      grant                                = { built_in_controls = ["block"] }
    }
    CA002 = {
      display_name          = "${local.name}-CA002-Global-BaseProtection-AllApps-UnknownPlatforms-Block"
      included_users        = ["All"]
      included_applications = ["All"]
      included_platforms    = ["all"]
      excluded_platforms    = ["android", "iOS", "windows", "macOS", "linux"]
      grant                 = { built_in_controls = ["block"] }
    }
    CA004 = {
      display_name                      = "${local.name}-CA004-Global-IdentityProtection-RegisterSecurityInfo-Untrusted-Require-TAPorStrongMFA"
      included_users                    = ["All"]
      excluded_guests_or_external_users = local.exclude_guests
      included_user_actions             = ["urn:user:registersecurityinfo"]
      included_locations                = ["All"]
      excluded_locations                = ["AllTrusted"]
      grant                             = { authentication_strength_policy_id = data.azuread_authentication_strength_policy.security_info_registration.id }
    }
    CA005 = {
      display_name          = "${local.name}-CA005-Global-BaseProtection-RegisterOrJoinDevice-AnyPlatform-Require-MFA"
      included_users        = ["All"]
      included_user_actions = ["urn:user:registerdevice"]
      grant                 = { built_in_controls = ["mfa"] }
    }
    CA006 = {
      display_name          = "${local.name}-CA006-Global-IdentityProtection-AzureManagement-AnyPlatform-Require-MFA"
      included_users        = ["All"]
      included_applications = [local.apps.azure_management]
      grant                 = { authentication_strength_policy_id = local.strength_mfa }
    }
    CA100 = {
      display_name          = "${local.name}-CA100-Admins-IdentityProtection-AllApps-AnyPlatform-Require-PhishingResistantMFA"
      included_roles        = local.privileged_roles
      included_applications = ["All"]
      grant                 = { authentication_strength_policy_id = data.azuread_authentication_strength_policy.phishing_resistant_admins.id }
    }
    CA101 = {
      display_name          = "${local.name}-CA101-Admins-DeviceProtection-AllApps-AnyPlatform-Require-CompliantOrHybridJoinedDevice"
      included_roles        = local.privileged_roles
      included_applications = ["All"]
      grant = {
        operator          = "OR"
        built_in_controls = ["compliantDevice", "domainJoinedDevice"]
      }
    }
    CA102 = {
      display_name          = "${local.name}-CA102-Admins-SessionProtection-AllApps-AnyPlatform-SignInFrequency-NoPersistentBrowser"
      included_roles        = local.privileged_roles
      included_applications = ["All"]
      session = {
        sign_in_frequency        = var.admin_sign_in_frequency_hours
        sign_in_frequency_period = "hours"
        persistent_browser_mode  = "never"
      }
    }
    CA200 = {
      display_name                      = "${local.name}-CA200-Internals-IdentityProtection-AllApps-AnyPlatform-Require-MFA"
      included_users                    = ["All"]
      excluded_guests_or_external_users = local.exclude_guests
      excluded_groups                   = [data.azuread_group.service_accounts.object_id]
      excluded_roles                    = [local.roles.directory_synchronization_accounts]
      included_applications             = ["All"]
      grant                             = { authentication_strength_policy_id = local.strength_mfa }
    }
    CA201 = {
      display_name                      = "${local.name}-CA201-Internals-AppProtection-Office365-iOSAndroid-Require-AppProtectionOrCompliantDevice"
      included_users                    = ["All"]
      excluded_guests_or_external_users = local.exclude_guests
      included_applications             = ["Office365"]
      client_app_types                  = ["browser", "mobileAppsAndDesktopClients"]
      included_platforms                = ["android", "iOS"]
      grant = {
        operator          = "OR"
        built_in_controls = ["compliantApplication", "compliantDevice"]
      }
    }
    CA202 = {
      display_name                      = "${local.name}-CA202-Internals-SessionProtection-AllApps-UnmanagedDevices-NoPersistentBrowser"
      included_users                    = ["All"]
      excluded_guests_or_external_users = local.exclude_guests
      included_applications             = ["All"]
      client_app_types                  = ["browser"]
      device_filter = {
        mode = "exclude"
        rule = "device.trustType -eq \"ServerAD\" -or device.isCompliant -eq True"
      }
      session = {
        sign_in_frequency        = 1
        sign_in_frequency_period = "hours"
        persistent_browser_mode  = "never"
      }
    }
    CA203 = {
      display_name                      = "${local.name}-CA203-Internals-DataProtection-Office365-UnmanagedDevices-AppEnforcedRestrictions"
      included_users                    = ["All"]
      excluded_guests_or_external_users = local.exclude_guests
      included_applications             = ["Office365"]
      client_app_types                  = ["browser"]
      session                           = { application_enforced_restrictions_enabled = true }
    }
    CA400 = {
      display_name = "${local.name}-CA400-Guests-IdentityProtection-AllApps-AnyPlatform-Require-MFA"
      included_guests_or_external_users = {
        types = local.all_guest_types
      }
      included_applications = ["All"]
      grant                 = { authentication_strength_policy_id = local.strength_mfa }
    }
  }

  country_block_policy = {
    CA003 = {
      display_name          = "${local.name}-CA003-Global-BaseProtection-AllApps-BlockedCountries-Block"
      included_users        = ["All"]
      included_applications = ["All"]
      included_locations    = [data.azuread_named_location.blocked_countries.object_id]
      grant                 = { built_in_controls = ["block"] }
    }
  }

  risk_policies = {
    CA300 = {
      display_name          = "${local.name}-CA300-Internals-IdentityProtection-AllApps-AnyPlatform-SignInRiskMediumHigh-Require-MFA"
      included_users        = ["All"]
      sign_in_risk_levels   = ["high", "medium"]
      included_applications = ["All"]
      grant                 = { authentication_strength_policy_id = local.strength_mfa }
      session = {
        sign_in_frequency_interval            = "everyTime"
        sign_in_frequency_authentication_type = "primaryAndSecondaryAuthentication"
      }
    }
    CA301 = {
      display_name          = "${local.name}-CA301-Internals-IdentityProtection-AllApps-AnyPlatform-UserRiskHigh-Require-MFAandPasswordChange"
      included_users        = ["All"]
      user_risk_levels      = ["high"]
      included_applications = ["All"]
      grant = {
        operator          = "AND"
        built_in_controls = ["mfa", "passwordChange"]
      }
      session = {
        sign_in_frequency_interval            = "everyTime"
        sign_in_frequency_authentication_type = "primaryAndSecondaryAuthentication"
      }
    }
  }

  workload_identity_policy = {
    CA500 = {
      display_name                = "${local.name}-CA500-WorkloadIdentities-AllApps-UntrustedLocations-Block"
      included_users              = ["None"]
      included_service_principals = ["ServicePrincipalsInMyTenant"]
      included_applications       = ["All"]
      included_locations          = ["All"]
      excluded_locations          = ["AllTrusted"]
      grant                       = { built_in_controls = ["block"] }
    }
  }

  policies_merged = merge(
    local.baseline_policies,
    { for k, p in local.country_block_policy : k => p if var.enable_country_block },
    { for k, p in local.risk_policies : k => p if var.enable_risk_policies },
    { for k, p in local.workload_identity_policy : k => p if var.enable_workload_identity_policy },
  )

  policies = {
    for k, p in local.policies_merged : k => merge(p, { state = lookup(var.policy_state_overrides, k, var.ca_state) })
  }

  token_protection_catalogue = {
    CA600 = {
      display_name          = "${local.name}-CA600-Admins-SessionProtection-ExchangeSharePointTeams-Windows-Require-TokenProtection"
      state                 = lookup(var.policy_state_overrides, "CA600", var.ca_state)
      included_roles        = local.privileged_roles
      included_applications = [local.apps.exchange_online, local.apps.sharepoint_online, local.apps.teams_services]
      included_platforms    = ["windows"]
    }
  }

  token_protection_policies = { for k, p in local.token_protection_catalogue : k => p if var.enable_token_protection }
}
