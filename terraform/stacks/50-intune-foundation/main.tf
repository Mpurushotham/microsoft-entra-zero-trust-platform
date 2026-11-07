module "rbac" {
  source = "../../modules/intune-rbac"

  name_prefix = var.name_prefix
  environment = var.environment

  scope_tags = {
    corporate = {
      description      = "Corporate-owned Windows devices"
      device_group_ids = local.windows_ids
    }
  }

  role_assignments = {
    for k, r in local.rbac_groups : k => {
      role_display_name = r.role
      member_group_ids  = [azuread_group.intune_role[k].object_id]
      scope_type        = r.scope_type
      scope_group_ids   = r.scope_type == "resourceScope" ? concat(values(local.device_group_ids), local.user_group_ids) : []
    }
  }
}

module "enrollment" {
  source = "../../modules/intune-enrollment"

  name_prefix           = var.name_prefix
  environment           = var.environment
  restriction_group_ids = local.user_group_ids
  device_categories     = var.device_categories
}

module "compliance" {
  source = "../../modules/intune-compliance"

  name_prefix                      = var.name_prefix
  environment                      = var.environment
  noncompliance_grace_period_hours = var.compliance_grace_period_hours

  device_threat_protection = {
    enabled = var.defender_for_endpoint_connected
    level   = "medium"
  }

  assignments = {
    windows               = { include_group_ids = local.windows_ids }
    macos                 = { include_group_ids = [local.device_group_ids["macos"]] }
    ios                   = { include_group_ids = [local.device_group_ids["ios"]] }
    android_fully_managed = { include_group_ids = [local.device_group_ids["android_corporate"]] }
    android_work_profile  = { include_group_ids = [local.device_group_ids["android_work_profile"]] }
  }
}

module "configuration" {
  source = "../../modules/intune-configuration"

  name_prefix = var.name_prefix
  environment = var.environment

  assignments = {
    credential_guard = { include_group_ids = local.windows_ids }
    os_hardening     = { include_group_ids = local.windows_ids }
  }
}

module "endpoint_security" {
  source = "../../modules/intune-endpoint-security"

  name_prefix = var.name_prefix
  environment = var.environment
  policies    = var.defender_for_endpoint_connected ? ["antivirus", "firewall", "asr", "edr", "bitlocker", "laps"] : ["antivirus", "firewall", "asr", "bitlocker", "laps"]
  asr_rules   = var.asr_rule_overrides

  assignments = {
    for p in ["antivirus", "firewall", "asr", "edr", "bitlocker", "laps"] : p => { include_group_ids = local.windows_ids }
  }
}

module "update_rings" {
  source = "../../modules/intune-update-rings"

  name_prefix = var.name_prefix
  environment = var.environment

  rings = {
    pilot = merge(var.update_rings["pilot"], {
      include_group_ids = [azuread_group.windows_ring_pilot.object_id]
    })
    broad = merge(var.update_rings["broad"], {
      include_group_ids = local.windows_ids
      exclude_group_ids = [azuread_group.windows_ring_pilot.object_id]
    })
  }

  feature_update_profiles = {
    corporate = {
      feature_update_version = var.feature_update_version
      include_group_ids      = local.windows_ids
    }
  }
}

module "app_protection" {
  source = "../../modules/intune-app-protection"

  name_prefix       = var.name_prefix
  environment       = var.environment
  protection_level  = var.app_protection_level
  include_group_ids = local.user_group_ids
}
