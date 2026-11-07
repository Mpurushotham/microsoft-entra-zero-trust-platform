module "break_glass" {
  source = "../../modules/entra-break-glass"

  name_prefix     = var.name_prefix
  environment     = var.environment
  account_aliases = var.break_glass_aliases
  usage_location  = var.usage_location
}

module "groups" {
  source = "../../modules/entra-groups"

  name_prefix              = var.name_prefix
  environment              = var.environment
  groups                   = local.groups
  default_owner_object_ids = var.group_owner_object_ids
}

module "administrative_units" {
  source = "../../modules/entra-administrative-units"

  name_prefix = var.name_prefix
  environment = var.environment
  administrative_units = merge(local.administrative_units, {
    "tier0-accounts" = merge(local.administrative_units["tier0-accounts"], {
      member_object_ids = [for a in module.break_glass.accounts : a.object_id]
    })
  })

  scoped_role_assignments = {
    "helpdesk-users-standard" = {
      administrative_unit_key = "users-standard"
      role_template_id        = local.role_template_ids.helpdesk_administrator
      principal_object_id     = module.groups.object_ids["pim-helpdesk-administrators"]
    }
  }
}

module "named_locations" {
  source = "../../modules/entra-named-locations"

  name_prefix = var.name_prefix
  environment = var.environment

  ip_locations = {
    "corporate-egress" = {
      ip_ranges = var.corporate_egress_ranges
      trusted   = true
    }
  }

  country_locations = {
    "allowed-countries" = {
      countries_and_regions = var.allowed_countries
    }
    "blocked-countries" = {
      countries_and_regions = var.blocked_countries
    }
  }
}

module "authentication_methods" {
  source = "../../modules/entra-authentication-methods"

  name_prefix        = var.name_prefix
  environment        = var.environment
  excluded_group_ids = [module.break_glass.exclusion_group_object_id]

  fido2 = {
    use_passkey_profiles = var.fido2_use_passkey_profiles
    passkey_types        = var.fido2_passkey_types
    attestation_enforced = var.fido2_attestation_enforced
  }

  disable_sms               = var.disable_sms_and_voice
  disable_voice             = var.disable_sms_and_voice
  complete_policy_migration = var.complete_auth_methods_migration
  authentication_strengths  = local.authentication_strengths
}

module "custom_security_attributes" {
  source = "../../modules/entra-custom-security-attributes"
  count  = var.enable_custom_security_attributes ? 1 : 0

  attribute_sets = local.custom_security_attribute_sets
}
